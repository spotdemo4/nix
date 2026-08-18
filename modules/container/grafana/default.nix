{
  lib,
  self,
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
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    secretType
    ;
  inherit (config.virtualisation.quadlet)
    volumes
    ;
  cfg = config.trev.containers.grafana;
  networks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  networkRef = name: (lib.attrByPath [ name ] { ref = name; } networks).ref;
  missingNetworks = builtins.filter (name: !(builtins.hasAttr name networks)) cfg.networkNames;
in
{
  options.trev.containers.grafana = {
    enable = mkEnableOption "the Grafana container";
    image = mkImageOption "docker.io/grafana/grafana-enterprise:13.2.0@sha256:f30823fd5aefb7a1acfcb41a93f5eef58f0e9167a06d192225550b6400975588";

    domain = mkOption {
      type = types.str;
      default = "grafana.trev.xyz";
      description = "Domain routed to Grafana.";
    };

    secret = mkOption {
      type = secretType;
      default = {
        ref = "grafana";
        file = self + /secrets/grafana.age;
      };
      description = "Grafana client configuration secret.";
    };

    networkNames = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Quadlet networks to attach to Grafana.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [ "3000" ];
      description = "Ports to publish from Grafana.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "grafana";
      description = "Name of the persistent Grafana data volume.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = missingNetworks == [ ];
        message = "trev.containers.grafana references undefined Quadlet networks: ${lib.concatStringsSep ", " missingNetworks}";
      }
    ];

    virtualisation.quadlet = {
      secrets.${cfg.secret.ref} = cfg.secret;

      containers.grafana.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        user = "root";
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/var/lib/grafana"
        ];
        publishPorts = cfg.publishPorts;
        networks = map networkRef cfg.networkNames;
        secrets = [
          {
            inherit (cfg.secret) ref;
            type = "mount";
            target = "/etc/secrets/client";
          }
        ];
        labels = {
          traefik = {
            enable = true;
            http.routers.grafana = {
              rule = "Host(`${cfg.domain}`)";
              middlewares = "secure-admin@file";
            };
          };
        };
      };

      volumes.${cfg.volumeName} = { };
    };
  };
}
