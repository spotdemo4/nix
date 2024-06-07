{ lib, config, pkgs, ... }:
 
{
  options.git-nix = {
    enable = lib.mkEnableOption "enable git";
  };

  config = lib.mkIf config.git-nix.enable {
    programs.git = {
      enable = true;
      config = {
        init = {
          defaultBranch = "main";
        };

        user = {
          name = "trev";
          email = "me@trev.xyz";
        };
      };
    };
  };
}
