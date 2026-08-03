{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    secretType
    ;
  cfg = config.trev.containers.wireguard;
in
{
  options.trev.containers.wireguard = {
    enable = mkEnableOption "the WireGuard server container";

    image = mkImageOption "lscr.io/linuxserver/wireguard:1.0.20260223-r0-ls119@sha256:ac43e1226878d2611315172d6ea357a95cb326ee73124b91108118efc8666889";

    serverConfigSecret = mkOption {
      type = secretType;
      description = "Podman secret containing the WireGuard server configuration.";
    };

  };

  config = mkIf cfg.enable {
    virtualisation.quadlet.containers.wireguard.containerConfig = mkContainer {
      image = cfg.image;
      pull = "missing";
      addCapabilities = [ "NET_ADMIN" ];
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      secrets = [
        {
          inherit (cfg.serverConfigSecret) ref;
          type = "mount";
          target = "/config/wg_confs/wg0.conf";
          uid = 0;
          gid = 0;
          mode = "0400";
        }
      ];
      networks = [ "host" ];
      healthCmd = builtins.toJSON [
        "wg"
        "show"
        "wg0"
      ];
      healthInterval = "1m";
      healthTimeout = "10s";
      healthStartPeriod = "10s";
      healthRetries = 3;
    };

    systemd.services.wireguard.restartTriggers = lib.optional (cfg.serverConfigSecret.file != null) (
      builtins.hashFile "sha256" cfg.serverConfigSecret.file
    );
  };
}
