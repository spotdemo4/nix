{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  trevbarPackage = inputs.trevbar.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.trev.programs.hyprland.enable = lib.mkEnableOption "Trev's Hyprland configuration";

  config = lib.mkIf config.trev.programs.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      extraConfig = builtins.readFile ./settings.lua;
    };

    systemd.user.services.trevbar = {
      Unit = {
        Description = "Trev's status bar";
        After = [ "hyprland-session.target" ];
        PartOf = [ "hyprland-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
        X-Restart-Triggers = [ trevbarPackage ];
      };

      Service = {
        ExecStart = lib.getExe trevbarPackage;
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install.WantedBy = [ "hyprland-session.target" ];
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-luminous
      ];
      config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.RemoteDesktop" = "luminous";
        "org.freedesktop.impl.portal.ScreenCast" = "hyprland";
      };
    };

    home.packages = with pkgs; [
      brightnessctl
    ];
  };
}
