{ config, lib, ... }:
{
  options.trev.programs.codex.enable = lib.mkEnableOption "Trev's Codex configuration";

  config = lib.mkIf config.trev.programs.codex.enable {
    programs.codex = {
      enable = true;
      settings = fromTOML (builtins.readFile ./config.toml);
      enableMcpIntegration = true;
    };
  };
}
