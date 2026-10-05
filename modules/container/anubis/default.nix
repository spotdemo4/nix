{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    filterAttrs
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    secretType
    toContentPath
    ;
  inherit (config.virtualisation.quadlet)
    networks
    volumes
    ;
  cfg = config.trev.containers.anubis;
  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;
  instanceEndpoints = mapAttrsToList (
    _: instance: "${instance.hostIp}:${toString instance.port}"
  ) enabledInstances;
in
{
  options.trev.containers.anubis = {
    enable = mkEnableOption "Anubis container instances";
    image = mkImageOption "ghcr.io/techarohq/anubis:v1.27.0@sha256:8828275668b7bc675679f100970f9714f731388fbbf66ae94de8aca952e3fc4a";

    instances = mkOption {
      default = { };
      description = "Service-specific Anubis instances.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "the ${name} Anubis container";

              domain = mkOption {
                type = types.str;
                description = "Domain whose requests this instance authorizes.";
              };

              hostIp = mkOption {
                type = types.str;
                description = "Host address trev-proxy uses to reach this instance.";
              };

              networkName = mkOption {
                type = types.str;
                default = name;
                description = "Quadlet network used by the protected service.";
              };

              target = mkOption {
                type = types.str;
                description = "URL of the protected service that Anubis forwards allowed requests to.";
              };

              policyFile = mkOption {
                type = types.path;
                description = "Anubis policy file for this service.";
              };

              port = mkOption {
                type = types.port;
                default = 8923;
                description = "Host port trev-proxy routes the domain to.";
              };

              signingKeySecret = mkOption {
                type = secretType;
                description = "Anubis Ed25519 signing key secret.";
              };
            };
          }
        )
      );
    };
  };

  config = mkIf (cfg.enable && enabledInstances != { }) {
    trev.proxy.routes = mapAttrs' (
      name: instance:
      nameValuePair "anubis-${name}" {
        domains = [ instance.domain ];
        address = instance.hostIp;
        inherit (instance) port;
        # Anubis only takes public addresses from X-Forwarded-For, so LAN
        # clients would have no X-Real-IP.
        forwardedHeaders = [
          "x-forwarded-for"
          "x-forwarded-proto"
          "x-forwarded-host"
          "x-real-ip"
        ];
      }
    ) enabledInstances;

    assertions =
      mapAttrsToList (name: instance: {
        assertion = builtins.hasAttr instance.networkName networks;
        message = "trev.containers.anubis.instances.${name} requires the '${instance.networkName}' Quadlet network to be defined";
      }) enabledInstances
      ++ [
        {
          assertion = builtins.length instanceEndpoints == builtins.length (lib.unique instanceEndpoints);
          message = "trev.containers.anubis instances must use unique hostIp and port combinations";
        }
      ];

    virtualisation.quadlet = {
      secrets = mapAttrs' (
        _: instance: nameValuePair instance.signingKeySecret.ref instance.signingKeySecret
      ) enabledInstances;

      containers = mapAttrs' (
        name: instance:
        let
          containerName = "anubis-${name}";
          policyFile = toContentPath instance.policyFile;
        in
        nameValuePair containerName {
          containerConfig = mkContainer {
            image = cfg.image;
            pull = "missing";
            environments = {
              BIND = ":8080";
              ED25519_PRIVATE_KEY_HEX_FILE = "/run/secrets/anubis-signing-key";
              POLICY_FNAME = "/etc/anubis/policy.yaml";
              PUBLIC_URL = "https://${instance.domain}";
              REDIRECT_DOMAINS = instance.domain;
              TARGET = instance.target;
            };
            volumes = [
              "${volumes.${containerName}.ref}:/data:U"
              "${policyFile}:/etc/anubis/policy.yaml:ro"
            ];
            secrets = [
              {
                inherit (instance.signingKeySecret) ref;
                type = "mount";
                target = "/run/secrets/anubis-signing-key";
                uid = 1000;
                gid = 1000;
                mode = "0400";
              }
            ];
            publishPorts = [
              "${instance.hostIp}:${toString instance.port}:8080"
            ];
            networks = [
              networks.${instance.networkName}.ref
            ];
            healthCmd = builtins.toJSON [
              "anubis"
              "--healthcheck"
            ];
            healthInterval = "1m";
            healthTimeout = "10s";
            healthStartPeriod = "5s";
            healthRetries = 3;
            healthOnFailure = "kill";
          };

          serviceConfig = {
            Restart = "on-failure";
            RestartSec = 5;
          };
        }
      ) enabledInstances;

      volumes = mapAttrs' (name: _: nameValuePair "anubis-${name}" { }) enabledInstances;
    };
  };
}
