{
  self,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
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
  inherit (config.virtualisation.quadlet) volumes;
  cfg = config.trev.containers.stack;
in
{
  options.trev.containers.stack = {
    enable = mkEnableOption "TrevStack server container";

    image = mkImageOption "trev.zip/template/stack/server:1.3.0@sha256:f07a1fcec40639100b0dfd92ebea9348f7806faab4a012ee2895f0618a506d75";

    domain = mkOption {
      type = types.str;
      default = "stack.trev.zip";
      description = "Domain routed to the TrevStack server.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "TrevStack port published on the host.";
    };

    trustedProxyCIDRs = mkOption {
      type = types.listOf types.str;
      default = [ "10.10.10.105/32" ];
      description = "Proxy CIDRs allowed to send PROXY protocol headers and set X-Forwarded-For.";
    };

    jwtSecret = mkOption {
      type = secretType;
      default = {
        ref = "stack-jwt";
        file = self + /secrets/stack-jwt.age;
      };
      description = "TrevStack session signing secret.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "stack";
      description = "Name of the persistent TrevStack data volume.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.stack = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
      proxyProtocol = true;
    };

    virtualisation.quadlet = {
      secrets.${cfg.jwtSecret.ref} = cfg.jwtSecret;

      containers.stack.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        user = "65532";
        group = "65532";
        # The SQLite database lives under $XDG_CONFIG_HOME/trevstack.
        environments = {
          XDG_CONFIG_HOME = "/data";
          AUTH_COOKIE_SECURE = "true";
          TRUSTED_PROXY_CIDRS = concatStringsSep "," cfg.trustedProxyCIDRs;
          PROXY_PROTOCOL = "true";
        };
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/data:U"
        ];
        secrets = [
          {
            inherit (cfg.jwtSecret) ref;
            type = "env";
            target = "JWT_SECRET";
          }
        ];
        publishPorts = [ "${toString cfg.port}:8080" ];
      };

      volumes.${cfg.volumeName} = { };
    };
  };
}
