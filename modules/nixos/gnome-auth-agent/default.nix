{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.trev.gnome-auth-agent;
in
{
  options.trev.gnome-auth-agent.enable = lib.mkEnableOption "GNOME polkit authentication agent";

  config = lib.mkIf cfg.enable {
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
