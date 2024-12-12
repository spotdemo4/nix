{ lib, config, pkgs, ... }:
 
{
  options.update-service = {
    enable = lib.mkEnableOption "enable update service";
    host = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = ''
        The hostname of the client.
      '';
    };
  };

  config = lib.mkIf config.update-service.enable {
    systemd.services.update = {
      description = "Update nixos in the background";
      path = [ "/run/current-system/sw" ];
      serviceConfig = {
        Type = "oneshot";
        Environment = "PATH=/run/current-system/sw/bin:$PATH";
        ExecStart = [
          "/run/current-system/sw/bin/update ${config.update-service.host}"
        ];
      };
    };

    systemd.timers.update = {
      description = "Timer to update nixos in the background";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "update.service";
      };
    };
  };
}