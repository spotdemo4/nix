{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    secretReferenceType
    ;
  cfg = config.trev.containers.traefik;
  valkeyConfig = lib.attrByPath [ "trev" "containers" "valkey" ] {
    enable = false;
    instances = { };
  } config;
  valkey = lib.attrByPath [ "instances" "traefik" ] {
    enable = false;
    ref = "valkey-traefik";
  } valkeyConfig;
  inherit (config.virtualisation.quadlet) networks volumes;

  acmeDomains = concatStringsSep "\n" (
    mapAttrsToList (
      main: sans:
      concatStringsSep "\n" (
        [
          "          - main: \"${main}\""
          "            sans:"
        ]
        ++ map (domain: "              - \"${domain}\"") sans
      )
    ) cfg.acmeDomains
  );

  configFile = pkgs.replaceVars ./config.yaml.in {
    acme = "/etc/traefik/acme";
    inherit acmeDomains;
    acmeEmail = cfg.acmeEmail;
    file = "/config/provider.yaml";
    logsEndpoint = cfg.logsEndpoint;
    redis = valkey.ref;
    tracesEndpoint = cfg.tracesEndpoint;
  };

  providerFile = pkgs.replaceVars ./provider.yaml {
    crowdsecAddress = cfg.crowdsecAddress;
    userAdmin = "/secrets/user-admin";
    userTrev = "/secrets/user-trev";
  };
in
{
  options.trev.containers.traefik = {
    enable = mkEnableOption "the Traefik container";

    image = mkImageOption "docker.io/traefik:v3.7.8@sha256:4299bbed850421258fc5448c2e0e6ad350981d4d335a68de11b92448aedbefe5";

    podmanSocket = mkOption {
      type = types.str;
      default = "/run/podman/podman.sock";
      description = "Host Podman socket exposed to Traefik.";
    };

    dashboardDomain = mkOption {
      type = types.str;
      default = "traefik.trev.xyz";
      description = "Domain routed to the Traefik dashboard.";
    };

    acmeEmail = mkOption {
      type = types.str;
      default = "me@trev.xyz";
      description = "Email address used for ACME registration.";
    };

    acmeDomains = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = { };
      description = "ACME certificate domains mapped to their subject alternative names.";
    };

    tracesEndpoint = mkOption {
      type = types.str;
      default = "10.10.10.109:4317";
      description = "OpenTelemetry gRPC traces endpoint.";
    };

    logsEndpoint = mkOption {
      type = types.str;
      default = "http://10.10.10.109:9428/insert/opentelemetry/v1/logs";
      description = "OpenTelemetry HTTP logs endpoint.";
    };

    crowdsecAddress = mkOption {
      type = types.str;
      default = "10.10.10.114:6061";
      description = "CrowdSec LAPI host and port.";
    };

    ports = {
      http = mkOption {
        type = types.port;
        default = 80;
        description = "HTTP entrypoint port.";
      };
      https = mkOption {
        type = types.port;
        default = 443;
        description = "HTTPS entrypoint port.";
      };
      rsync = mkOption {
        type = types.port;
        default = 873;
        description = "Rsync entrypoint port.";
      };
      rsyncTls = mkOption {
        type = types.port;
        default = 874;
        description = "Rsync TLS entrypoint port.";
      };
      metrics = mkOption {
        type = types.port;
        default = 8080;
        description = "Prometheus metrics port.";
      };
      plex = mkOption {
        type = types.port;
        default = 32400;
        description = "Plex entrypoint port.";
      };
      minecraft = mkOption {
        type = types.port;
        default = 25565;
        description = "Minecraft entrypoint port.";
      };
      syncthing = mkOption {
        type = types.port;
        default = 22000;
        description = "Syncthing TCP and UDP entrypoint port.";
      };
    };

    secrets = {
      cloudflareDns = mkOption {
        type = secretReferenceType;
        description = "Podman secret containing the Cloudflare DNS API token.";
      };
      crowdsec = mkOption {
        type = secretReferenceType;
        description = "Podman secret containing the CrowdSec LAPI key.";
      };
      turnstileSiteKey = mkOption {
        type = secretReferenceType;
        description = "Podman secret containing the Cloudflare Turnstile site key.";
      };
      turnstileSecretKey = mkOption {
        type = secretReferenceType;
        description = "Podman secret containing the Cloudflare Turnstile secret key.";
      };
      userAdmin = mkOption {
        type = secretReferenceType;
        description = "Podman secret containing the admin basic-auth users file.";
      };
      userTrev = mkOption {
        type = secretReferenceType;
        description = "Podman secret containing the trev basic-auth users file.";
      };
    };

    acmeVolumeName = mkOption {
      type = types.str;
      default = "acme";
      description = "Quadlet volume containing ACME state.";
    };

    networkName = mkOption {
      type = types.str;
      default = "traefik";
      description = "Quadlet network used by Traefik and proxied containers.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = valkeyConfig.enable && valkey.enable;
        message = "trev.containers.traefik requires trev.containers.valkey.enable = true and trev.containers.valkey.instances.traefik.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.traefik = {
        containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          secrets = [
            "${cfg.secrets.cloudflareDns.env},target=CF_DNS_API_TOKEN"
            "${cfg.secrets.crowdsec.mount},target=/secrets/crowdsec/lapi_key"
            "${cfg.secrets.turnstileSiteKey.mount},target=/secrets/turnstile/site_key"
            "${cfg.secrets.turnstileSecretKey.mount},target=/secrets/turnstile/secret_key"
            "${cfg.secrets.userAdmin.mount},target=/secrets/user-admin"
            "${cfg.secrets.userTrev.mount},target=/secrets/user-trev"
          ];
          volumes = [
            "${cfg.podmanSocket}:/var/run/docker.sock"
            "${configFile}:/etc/traefik/traefik.yml"
            "${providerFile}:/config/provider.yaml"
            "${volumes.${cfg.acmeVolumeName}.ref}:/etc/traefik/acme"
            "${./captcha.html}:/captcha.html"
          ];
          publishPorts = [
            "${toString cfg.ports.http}:80"
            "${toString cfg.ports.https}:443"
            "${toString cfg.ports.rsync}:873"
            "${toString cfg.ports.rsyncTls}:874"
            "${toString cfg.ports.metrics}:8080"
            "${toString cfg.ports.plex}:32400"
            "${toString cfg.ports.minecraft}:25565"
            "${toString cfg.ports.syncthing}:22000/tcp"
            "${toString cfg.ports.syncthing}:22000/udp"
          ];
          networks = [
            networks.${cfg.networkName}.ref
          ];
          labels = {
            traefik = {
              enable = true;
              http.routers.api = {
                rule = "Host(`${cfg.dashboardDomain}`)";
                service = "api@internal";
                middlewares = "secure-trev@file";
              };
            };
          };
        };

        unitConfig = {
          After = "podman.socket";
          BindsTo = "podman.socket";
          ReloadPropagatedFrom = "podman.socket";
        };
      };

      volumes.${cfg.acmeVolumeName} = { };
      networks.${cfg.networkName} = { };
    };
  };
}
