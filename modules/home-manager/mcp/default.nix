{
  self,
  config,
  pkgs,
  ...
}:
let
  kagiWrapper = pkgs.writeShellApplication {
    name = "kagi-mcp-wrapper";
    runtimeInputs = with pkgs; [ trev.kagimcp ];
    text = ''
      KAGI_API_KEY="$(cat "${config.age.secrets."kagi".path}")"
      export KAGI_API_KEY
      kagimcp "$@"
    '';
  };
in
{
  age.secrets."kagi".file = self + /secrets/kagi.age;

  programs.mcp = {
    enable = true;
    servers = {
      kagi = {
        command = "${kagiWrapper}/bin/kagi-mcp-wrapper";
        args = [ ];
      };
    };
  };
}
