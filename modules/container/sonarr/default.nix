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
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  inherit (containerOptions) mkContainer;
  cfg = config.trev.containers.sonarr;
  inherit (config.virtualisation.quadlet) volumes;
in
{
  options.trev.containers.sonarr = {
    enable = mkEnableOption "Sonarr container";
    image = containerOptions.mkImageOption "lscr.io/linuxserver/sonarr:4.0.19@sha256:24acea2956a0ccb11f103877d9f4f8576600fb34bff34820ed749c2256dab89f";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Sonarr.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Sonarr.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Sonarr.";
    };
    poolPath = mkOption {
      type = types.str;
      default = "/mnt/pool";
      description = "Host media pool path.";
    };
    domainPattern = mkOption {
      type = types.str;
      default = "sonarr.trev.(zip|kiwi)";
      description = "Traefik HostRegexp pattern for Sonarr.";
    };
    port = mkOption {
      type = types.port;
      default = 8989;
      description = "Sonarr port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.sonarr.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timeZone;
        };
        volumes = [
          "${volumes.sonarr.ref}:/config"
          "${cfg.poolPath}:/pool"
        ];
        publishPorts = [ (toString cfg.port) ];
        networks = [ config.virtualisation.quadlet.networks.sonarr.ref ];
        labels = {
          traefik = {
            enable = true;
            http.routers.sonarr = {
              rule = "HostRegexp(`${cfg.domainPattern}`)";
              middlewares = "secure-admin@file";
            };
          };
        };
      };

      volumes.sonarr = { };
      networks.sonarr = { };
    };
  };
}
