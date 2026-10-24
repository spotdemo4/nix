{
  lib,
  config,
  self,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    secretType
    ;
  inherit (config.virtualisation.quadlet)
    containers
    volumes
    ;
  cfg = config.trev.containers.dispatcharr;
  gluetunConfig = lib.attrByPath [ "trev" "containers" "gluetun" ] {
    enable = false;
    instances = { };
  } config;
  gluetun = lib.attrByPath [ "instances" cfg.gluetunInstance ] {
    enable = false;
    ref = "gluetun-${cfg.gluetunInstance}";
  } gluetunConfig;
  gluetunContainer = lib.attrByPath [ gluetun.ref ] { ref = gluetun.ref; } containers;
in
{
  options.trev.containers.dispatcharr = {
    enable = mkEnableOption "Dispatcharr container";
    image = mkImageOption "ghcr.io/dispatcharr/dispatcharr:0.33.0@sha256:96bc548978c68e684677da7895692eeeefb7f0b2edfa38311dac2b702c61d236";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Dispatcharr.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Dispatcharr.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Dispatcharr.";
    };
    domains = mkOption {
      type = types.listOf types.str;
      default = [ "dispatcharr.trev.zip" ];
      description = "Domains routed to Dispatcharr.";
    };
    port = mkOption {
      type = types.port;
      default = 9191;
      description = "Dispatcharr web port, published on the host by its Gluetun instance.";
    };
    gluetunInstance = mkOption {
      type = types.str;
      default = "dispatcharr";
      description = "Gluetun instance whose network namespace Dispatcharr joins.";
    };
    protonVpnSecret = mkOption {
      type = secretType;
      default = {
        ref = "protonvpn-dispatcharr";
        file = self + /secrets/protonvpn-dispatcharr.age;
      };
      description = "Proton VPN WireGuard private key secret.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.dispatcharr = {
      inherit (cfg) domains port;
    };

    assertions = [
      {
        assertion = gluetunConfig.enable && gluetun.enable;
        message = "trev.containers.dispatcharr requires trev.containers.gluetun.enable = true and trev.containers.gluetun.instances.${cfg.gluetunInstance}.enable = true";
      }
    ];

    virtualisation.quadlet = {
      secrets.${cfg.protonVpnSecret.ref} = cfg.protonVpnSecret;

      containers.dispatcharr = {
        containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          environments = {
            PUID = toString cfg.uid;
            PGID = toString cfg.gid;
            TZ = cfg.timeZone;
            DISPATCHARR_ENV = "aio";
            DISPATCHARR_PORT = toString cfg.port;
            DISPATCHARR_LOG_LEVEL = "info";
            REDIS_HOST = "localhost";
            CELERY_BROKER_URL = "redis://localhost:6379/0";
          };
          volumes = [ "${volumes.dispatcharr.ref}:/data" ];
          networks = [ "container:${gluetun.ref}" ];
        };

        unitConfig = {
          BindsTo = gluetunContainer.ref;
          After = gluetunContainer.ref;
          ReloadPropagatedFrom = gluetunContainer.ref;
        };

        serviceConfig.RestartSec = "20s";
      };

      volumes.dispatcharr = { };
    };
  };
}
