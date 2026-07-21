{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (import ../../../lib/container-options.nix { inherit lib; })
    mkContainer
    mkImageOption
    networks
    ;
  cfg = config.trev.containers.tautulli;
  plex = lib.attrByPath [ "trev" "containers" "plex" ] { enable = false; } config;
  inherit (config.virtualisation.quadlet) volumes;
  quadletNetworks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  plexNetwork = lib.attrByPath [ "plex" ] { ref = "plex"; } quadletNetworks;
in
{
  options.trev.containers.tautulli = {
    enable = mkEnableOption "Tautulli container";
    image = mkImageOption "lscr.io/linuxserver/tautulli:latest@sha256:ef7f4329e5029f83bc93a6fef9a06e67b97652573ce3d62402645ba0d933a0be";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Tautulli.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Tautulli.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Tautulli.";
    };
    domainPattern = mkOption {
      type = types.str;
      default = "tautulli.trev.(zip|kiwi)";
      description = "Traefik HostRegexp pattern for Tautulli.";
    };
    port = mkOption {
      type = types.port;
      default = 8181;
      description = "Tautulli port published on the host.";
    };
    networks = networks // {
      default = [ plexNetwork.ref ];
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = plex.enable;
        message = "trev.containers.tautulli requires trev.containers.plex.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.tautulli.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timeZone;
        };
        volumes = [ "${volumes.tautulli.ref}:/config" ];
        publishPorts = [ (toString cfg.port) ];
        networks = cfg.networks;
        labels = {
          traefik = {
            enable = true;
            http.routers.tautulli = {
              rule = "HostRegexp(`${cfg.domainPattern}`)";
              middlewares = "secure-trev@file";
            };
          };
        };
      };

      volumes.tautulli = { };
    };
  };
}
