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
    systemd.services.systemd-journal-upload.serviceConfig = {
      ExecStart = [
        ""
        "${nonfatalJournalUpload}/bin/systemd-journal-upload-nonfatal"
      ];
      NotifyAccess = "all";
    };
  };
}
