{ lib, config, pkgs, inputs, ... }:
 
{
  options.mako-conf = {
    enable = lib.mkEnableOption "enable mako config";
  };

  config = lib.mkIf config.mako-conf.enable {
    services.mako = {
      enable = true;
      catppuccin = {
        enable = true;
        flavor = "mocha";
      };
    };
  };
}
