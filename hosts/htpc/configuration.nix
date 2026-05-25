# HTPC config
{
  inputs,
  lib,
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
      initial_session = {
        user = "trev";
        command = "start-hyprland";
      };
      default_session = {
        user = "trev";
        command = "${pkgs.greetd}/bin/agreety --cmd start-hyprland";
      };
    };
  };

  # Home manager
  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
    users = {
      trev = {
        imports = [ (self + /users/trev.nix) ];
        wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
          hl.on("hyprland.start", function()
              hl.exec_cmd("steam")
          end)
        '';
      };
    };
  };
}
