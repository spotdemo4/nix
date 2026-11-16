{ config, lib, ... }:
{
  # resolvconf runs `systemctl try-restart nscd.service` on every resolv.conf change
  # (libc_restart in /etc/resolvconf.conf). NetworkManager rewrites resolv.conf several times
  # while the network comes up, which exceeds the default start limit of 5 starts in 10s, so
  # nscd failed with start-limit-hit on every boot and try-restart never brought it back.
  # Without nscd, programs can't resolve systemd's dynamic users, so niks3-hook's
  # `nix-store --add-root` failed with "cannot determine user's home directory".
  config = lib.mkIf config.services.nscd.enable {
    systemd.services.nscd.startLimitIntervalSec = 0;
  };
}
