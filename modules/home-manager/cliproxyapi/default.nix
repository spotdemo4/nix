{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.trev.services.cliproxyapi;
  yamlFormat = pkgs.formats.yaml { };
  generatedConfig = yamlFormat.generate "cliproxyapi.yaml" (
    lib.recursiveUpdate {
      host = "127.0.0.1";
      port = 8317;
      "auth-dir" = "${config.xdg.dataHome}/cliproxyapi";
      "api-keys" = [ ];
      debug = false;
      "request-log" = false;
      "logging-to-file" = false;
      "usage-statistics-enabled" = false;
      "remote-management" = {
        "allow-remote" = false;
        "secret-key" = "";
        "disable-control-panel" = true;
      };
    } cfg.settings
  );
  configPath =
    if cfg.configFile == null then
      "${config.xdg.configHome}/cliproxyapi/config.yaml"
    else
      toString cfg.configFile;
  package = pkgs.writeShellApplication {
    name = "cli-proxy-api";
    text = ''
      exec ${lib.getExe cfg.package} --config ${lib.escapeShellArg configPath} "$@"
    '';
  };
in
{
  options.trev.services.cliproxyapi = {
    enable = lib.mkEnableOption "CLIProxyAPI user service";

    package = lib.mkPackageOption pkgs.trev "cliproxyapi" { };

    configFile = lib.mkOption {
      type = with lib.types; nullOr (either path str);
      default = null;
      description = ''
        External CLIProxyAPI configuration file. When set, settings are ignored.
        Use this for configurations containing secrets that must not enter the Nix store.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        CLIProxyAPI settings merged with safe local-only defaults and rendered as YAML.
        Do not place secrets here because the generated configuration is stored in the Nix store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];

    xdg.configFile = lib.mkIf (cfg.configFile == null) {
      "cliproxyapi/config.yaml".source = generatedConfig;
    };

    systemd.user.services.cliproxyapi = {
      Unit = {
        Description = "CLIProxyAPI";
        Documentation = "https://help.router-for.me/";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
      };

      Service = {
        ExecStart = lib.getExe package;
        Restart = "on-failure";
        RestartSec = "5s";
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
