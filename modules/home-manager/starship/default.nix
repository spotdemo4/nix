{ config, lib, ... }:
{
  options.trev.programs.starship.enable = lib.mkEnableOption "Trev's Starship configuration";

  config = lib.mkIf config.trev.programs.starship.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        container.disabled = true;
        command_timeout = 3600000;
        git_status = {
          ahead = "↑\${count}";
          behind = "↓\${count}";
          diverged = "↕↑\${ahead_count}↓\${behind_count}";
        };
      };
    };

    catppuccin.starship = {
      enable = true;
      flavor = "mocha";
    };
  };
}
