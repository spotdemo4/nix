{ lib, config, pkgs, ... }:
 
{
  options.sddm-nix = {
    enable = lib.mkEnableOption "enable sddm";
  };

  config = lib.mkIf config.sddm-nix.enable {
    # Install catppuccin-mocha
    environment.systemPackages = with pkgs; [
      (catppuccin-sddm.override {
        flavor = "mocha";
      })
    ];

    # Create service
    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      wayland.enable = true;
      theme = "catppuccin-mocha";
      extraPackages = with pkgs.kdePackages; [
        breeze-icons
        kirigami
        plasma5support
        qtsvg
        qtvirtualkeyboard
      ];
    };
  };
}