# Laptop config
{
  inputs,
  self,
  pkgs,
  ...
}:
{
  imports = [
    (self + /templates/client)
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
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
    users = {
      root.imports = [ (self + /users/root.nix) ];
      trev.imports = [ (self + /users/trev.nix) ];
    };
  };

  # Power metrics
  services.upower.enable = true;
}
