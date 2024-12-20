{ lib, config, pkgs, ... }:
 
{
  options.updater = {
    enable = lib.mkEnableOption "enable updater service";
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = ''
        The hostname of the client.
      '';
    };
  };

  config = lib.mkIf config.updater.enable {
    systemd.services.update = {
      description = "Update nixos in the background";
      path = [ "/run/current-system/sw" ];
      serviceConfig = {
        Type = "oneshot";
        Environment = "PATH=/run/current-system/sw/bin:$PATH";
        ExecStart = [
          "/run/current-system/sw/bin/update ${config.updater.hostname}"
        ];
      };
    };

    systemd.timers.update = {
      description = "Timer to update nixos in the background";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "15min";
        OnCalendar = "daily";
        RandomizedDelaySec = "1h";
        Unit = "update.service";
      };
    };
  };
}