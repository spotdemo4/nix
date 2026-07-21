{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  inherit (containerOptions) mkContainer;
  cfg = config.trev.containers.seerr;
  sonarr = lib.attrByPath [ "trev" "containers" "sonarr" ] { enable = false; } config;
  radarr = lib.attrByPath [ "trev" "containers" "radarr" ] { enable = false; } config;
  plex = lib.attrByPath [ "trev" "containers" "plex" ] { enable = false; } config;
  inherit (config.virtualisation.quadlet) volumes;
  networks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  sonarrNetwork = lib.attrByPath [ "sonarr" ] { ref = "sonarr"; } networks;
  radarrNetwork = lib.attrByPath [ "radarr" ] { ref = "radarr"; } networks;
  plexNetwork = lib.attrByPath [ "plex" ] { ref = "plex"; } networks;
in
{
  options.trev.containers.seerr = {
    enable = mkEnableOption "Seerr container";
    image = containerOptions.mkImageOption "ghcr.io/seerr-team/seerr:v3.3.0@sha256:c92d2dc117f62185e7bcb88cd56efd374ea79210eaf433275449e8d5988eb5a8";
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Seerr.";
    };
    logLevel = mkOption {
      type = types.str;
      default = "debug";
      description = "Seerr log level.";
    };
    domains = mkOption {
      type = types.listOf types.str;
      default = [
        "overseerr.trev.xyz"
        "seerr.trev.xyz"
      ];
      description = "Domains routed to Seerr by Traefik.";
    };
    port = mkOption {
      type = types.port;
      default = 5055;
      description = "Seerr port published on the host.";
    };
    networks = containerOptions.networks // {
      default = [
        sonarrNetwork.ref
        radarrNetwork.ref
        plexNetwork.ref
      ];
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = sonarr.enable;
        message = "trev.containers.seerr requires trev.containers.sonarr.enable = true";
      }
      {
        assertion = radarr.enable;
        message = "trev.containers.seerr requires trev.containers.radarr.enable = true";
      }
      {
        assertion = plex.enable;
        message = "trev.containers.seerr requires trev.containers.plex.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.seerr.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          LOG_LEVEL = cfg.logLevel;
          TZ = cfg.timeZone;
        };
        volumes = [ "${volumes.seerr.ref}:/app/config" ];
        publishPorts = [ (toString cfg.port) ];
        networks = cfg.networks;
        labels = {
          traefik = {
            enable = true;
            http.routers.seerr = {
              rule = concatMapStringsSep " || " (domain: "Host(`${domain}`)") cfg.domains;
              middlewares = "secure@file";
            };
          };
        };
      };

      volumes.seerr = { };
    };
  };
}
