{ lib, config, pkgs, inputs, ... }:
 
{
  options.mako-conf = {
    enable = lib.mkEnableOption "enable mako config";
  };

  config = lib.mkIf config.mako-conf.enable {
    services.mako = {
      enable = true;
      defaultTimeout = 5000;
      catppuccin = {
        enable = true;
        flavor = "mocha";
      };
    };
  };
}
