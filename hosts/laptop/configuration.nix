# Laptop config
{
  self,
  pkgs,
  ...
}:
{
  imports = [
    (self + /modules/nixos/profiles/workstation.nix)
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    nvtopPackages.intel # intel gpu monitoring
  ];

  nix.distributedBuilds = true; # Enable remote builds

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "trev";
        command = "${pkgs.greetd}/bin/agreety --cmd start-hyprland";
      };
    };
  };

  # Bluetooth
  hardware = {
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Home manager
  home-manager = {
    users = {
      root.imports = [ (self + /modules/home-manager/profiles/root.nix) ];
      trev.imports = [ (self + /modules/home-manager/profiles/trev/workstation.nix) ];
    };
  };

  # Power metrics
  services.upower.enable = true;
}
