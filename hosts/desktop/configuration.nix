# Desktop config
{
  inputs,
  self,
  pkgs,
  ...
}:
{
  imports = [
    (self + /hosts/client.nix)
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    nvtopPackages.intel # intel gpu monitoring
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

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
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

  # RGB lighting control
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    startupProfile = "trev.orp";
  };

  services.fwupd.enable = true; # firmware updates
  boot.kernelPackages = pkgs.linuxPackages_latest; # latest kernel
  nix.settings.eval-cores = 0; # try out eval cores
}
