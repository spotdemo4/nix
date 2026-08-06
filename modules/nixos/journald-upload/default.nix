{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.journald.upload;

  nonfatalJournalUpload = pkgs.writeShellApplication {
    name = "systemd-journal-upload-nonfatal";
    text = ''
      # Let the child uploader claim the inherited watchdog interval.
      unset WATCHDOG_PID

      # Keep transient uploader failures from failing a NixOS configuration switch.
      ${config.systemd.package}/lib/systemd/systemd-journal-upload --save-state || true
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    services.journald.extraConfig = lib.mkDefault ''
      RateLimitIntervalSec=30s
      RateLimitBurst=1000
      SystemMaxUse=500M
    '';

    # Throttle noisy units that dominated 75% of ingest (see DuckMetrics report).
    systemd.services.systemd-networkd.serviceConfig.LogRateLimitIntervalSec = lib.mkDefault "30s";
    systemd.services.systemd-networkd.serviceConfig.LogRateLimitBurst = lib.mkDefault 500;
    systemd.services.cadvisor.serviceConfig.LogRateLimitIntervalSec = lib.mkDefault "30s";
    systemd.services.cadvisor.serviceConfig.LogRateLimitBurst = lib.mkDefault 500;

    systemd.services.systemd-journal-upload.serviceConfig = {
      ExecStart = [
        ""
        "${nonfatalJournalUpload}/bin/systemd-journal-upload-nonfatal"
      ];
      NotifyAccess = "all";
      RestartSec = lib.mkForce "30s";
    };
  };
}
