{
  config,
  lib,
  pkgs,
  ...
}:
let
  # kept while the user is idle, for the NixOS updater's idle check (trev.update.idle)
  idleFile = "$XDG_RUNTIME_DIR/idle";
in
{
  options.trev.services.hypridle.enable = lib.mkEnableOption "Trev's Hypridle configuration";

  config = lib.mkIf config.trev.services.hypridle.enable {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = 300; # 5 minutes
            on-timeout = "${lib.getExe' pkgs.coreutils "touch"} \"${idleFile}\"";
            on-resume = "${lib.getExe' pkgs.coreutils "rm"} -f \"${idleFile}\"";
          }
          {
            timeout = 600; # 10 minutes
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 900; # 15 minutes
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 1800; # 30 minutes
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };

    # a new hypridle starts out active, so it would never remove a file left by the last one
    systemd.user.services.hypridle.Service.ExecStartPre =
      "${lib.getExe' pkgs.coreutils "rm"} -f %t/idle";
  };
}
