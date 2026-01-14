# Desktop config
{
  inputs,
  self,
  pkgs,
  trev,
  ...
}:
{
  imports = [
    (self + /hosts/client.nix)
    ./hardware-configuration.nix
  ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "trev";
        command = "${pkgs.greetd}/bin/agreety --cmd start-hyprland";
      };
    };
  };

  # Home manager
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self trev;
    };
    users = {
      trev.imports = [ (self + /users/trev.nix) ];
    };
  };

  # Scanner support
  hardware.sane = {
    enable = true;
    brscan5.enable = true;
  };

  # Latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Try out eval cores
  nix.settings.eval-cores = 0;
}
