{ lib, config, pkgs, ... }:
 
{
  options.sddm-nix = {
    enable = lib.mkEnableOption "enable sddm";
  };

  config = lib.mkIf config.sddm-nix.enable {
    # Create service
    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      wayland.enable = true;
      catppuccin = {
        enable = true;
        flavor = "mocha";
      };
    };
  };
}