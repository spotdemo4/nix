{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.trev.programs.forgejo-cli;
  host = "trev.zip";
  login = ''{type: "Application", token: ($token | rtrimstr("\n"))}'';
  loginCurrent = pkgs.writeText "fj-login-current.jq" ".hosts[$host] == ${login}";
  setLogin = pkgs.writeText "fj-set-login.jq" ".hosts[$host] = ${login}";

  # fj only reads tokens from its keys.json, so write the Forgejo token into it
  # for trev.zip before every run. This also keeps it current when the secret is
  # rotated, and leaves any other hosts fj has logged in to alone.
  wrapper = pkgs.writeShellApplication {
    name = "fj";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = ''
      token_file="${config.trev.mcp.forgejoTokenFile}"
      keys="''${XDG_DATA_HOME:-$HOME/.local/share}/forgejo-cli/keys.json"
      jq_args=(--arg host "${host}" --rawfile token "$token_file")

      if ! jq -e "''${jq_args[@]}" -f ${loginCurrent} "$keys" >/dev/null 2>&1; then
        umask 077
        mkdir -p "$(dirname "$keys")"
        tmp="$(mktemp "$keys.XXXXXX")"
        trap 'rm -f "$tmp"' EXIT
        if [[ -s "$keys" ]]; then cat "$keys"; else echo '{}'; fi |
          jq "''${jq_args[@]}" -f ${setLogin} >"$tmp"
        mv -f "$tmp" "$keys"
        trap - EXIT
      fi

      # Commands run outside a Forgejo checkout go to trev.zip.
      export FJ_FALLBACK_HOST="''${FJ_FALLBACK_HOST:-https://${host}}"
      exec ${lib.getExe pkgs.forgejo-cli} "$@"
    '';
  };
in
{
  options.trev.programs.forgejo-cli.enable =
    lib.mkEnableOption "fj, the Forgejo CLI, logged in to ${host}";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.trev.mcp.enable;
        message = "trev.programs.forgejo-cli needs trev.mcp.enable for the Forgejo token.";
      }
    ];

    # The wrapper comes first so its bin/fj wins over the unwrapped one, while
    # the shell completions still come from forgejo-cli.
    home.packages = [
      (pkgs.symlinkJoin {
        name = "fj";
        paths = [
          wrapper
          pkgs.forgejo-cli
        ];
      })
    ];
  };
}
