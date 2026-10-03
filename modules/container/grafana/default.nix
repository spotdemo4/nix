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
    image = mkImageOption "docker.io/grafana/grafana-enterprise:13.2.3@sha256:06f65b30ff6513f55316beb6ff3e22d0132189297032ada2dfdc116f95663a60";

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

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Grafana port published on the host.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [ "${toString cfg.port}:3000" ];
      defaultText = lib.literalExpression ''[ "''${toString cfg.port}:3000" ]'';
      description = "Ports to publish from Grafana.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "grafana";
      description = "Name of the persistent Grafana data volume.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.grafana = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
      auth = "admin";
    };

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
      };

      volumes.${cfg.volumeName} = { };
    };
  };
}
