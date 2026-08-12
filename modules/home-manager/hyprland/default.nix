{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  trevbarPackage = inputs.trevbar.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Temporary override for https://github.com/waycrate/xdg-desktop-portal-luminous/pull/217
  luminousPackage = pkgs.trev.xdg-desktop-portal-luminous.overrideAttrs (
    finalAttrs: _previousAttrs: {
      version = "0.1.21-pr217-f13071e";

      src = pkgs.fetchFromGitHub {
        owner = "waycrate";
        repo = "xdg-desktop-portal-luminous";
        rev = "f13071ebf810c6cf181b18ff8c7c3c76702d581a";
        hash = "sha256-6GD/6412KIlNgGc8EmNJiNQrFsj/Jec94Y+gHYnyBXw=";
      };

      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname version src;
        hash = "sha256-N6TteUB3AC+LNxglvgQQ4RxRSaZk6E0f42BbYd3d+Rk=";
      };
    }
  );
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
        luminousPackage
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
