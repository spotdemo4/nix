{pkgs, ...}: {
  systemd.services."delete-garbage" = {
    description = "Delete nixos garbage in the background";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      set -eu
      ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 7d
    '';
  };

  systemd.timers."delete-garbage" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "delete-garbage.service";
    };
  };
}
