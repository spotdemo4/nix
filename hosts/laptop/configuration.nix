# Laptop config
{
  inputs,
  self,
  pkgs,
  ...
}: {
  imports = [
    (self + /hosts/client.nix)
    ./hardware-configuration.nix
  ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "trev";
        command = "${pkgs.greetd}/bin/agreety --cmd hyprland";
      };
    };
  };

  # Home manager
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
    users = {
      trev.imports = [(self + /users/trev.nix)];
    };
  };

  # Power metrics
  services.upower.enable = true;
}
