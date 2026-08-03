{ config, lib, ... }:
{
  config = lib.mkIf config.virtualisation.podman.enable {
    systemd.services.podman.environment.LOGGING = "--log-level=error";
  };
}
