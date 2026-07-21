{
  config,
  lib,
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
    ;
  cfg = config.trev.containers.cobalt;
  gluetunConfig = lib.attrByPath [ "trev" "containers" "gluetun" ] {
    enable = false;
    instances = { };
  } config;
  gluetun = lib.attrByPath [ "instances" "cobalt" ] {
    enable = false;
    ref = "gluetun-cobalt";
  } gluetunConfig;
in
{
  options.trev.containers.cobalt = {
    enable = mkEnableOption "Cobalt container";

    image = mkImageOption "ghcr.io/imputnet/cobalt:11.5@sha256:01637bc0ae6668f132f66b2dd992fc71865b7373ff483a406afa81d679118fc0";

    apiUrl = mkOption {
      type = types.str;
      default = "https://cobalt-api.trev.zip/";
      description = "Public URL advertised by the Cobalt API.";
    };

    domain = mkOption {
      type = types.str;
      default = "cobalt-api.trev.zip";
      description = "Domain routed to the Cobalt API.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = gluetunConfig.enable && gluetun.enable;
        message = "trev.containers.cobalt requires trev.containers.gluetun.enable = true and trev.containers.gluetun.instances.cobalt.enable = true";
      }
    ];

    virtualisation.quadlet.containers.cobalt = {
      containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments.API_URL = cfg.apiUrl;
        networks = [
          "container:${gluetun.ref}"
        ];
        labels = {
          traefik = {
            enable = true;
            http.routers.cobalt.rule = "Host(`${cfg.domain}`)";
          };
        };
      };

      unitConfig = {
        After = gluetun.ref;
        BindsTo = gluetun.ref;
        ReloadPropagatedFrom = gluetun.ref;
      };
    };
  };
}
