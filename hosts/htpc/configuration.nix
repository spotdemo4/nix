# HTPC config
{
  lib,
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
    users = {
      root.imports = [ (self + /modules/home-manager/profiles/root.nix) ];
      trev = {
        imports = [ (self + /modules/home-manager/profiles/trev/workstation.nix) ];
        wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
          hl.on("hyprland.start", function()
              hl.exec_cmd("steam")
          end)
        '';
      };
    };
  };
}
