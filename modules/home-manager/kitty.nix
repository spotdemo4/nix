{ lib, config, pkgs, inputs, ... }:
 
{
  options.kitty-conf = {
    enable = lib.mkEnableOption "enable kitty config";
  };

  config = lib.mkIf config.kitty-conf.enable {
    programs.kitty = {
      enable = true;
      catppuccin = {
        enable = true;
        flavor = "mocha";
      };
    };
  };
}
