{
  self,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    boolToString
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
  cfg = config.trev.containers.pr-tracker;
in
{
  options.trev.containers.pr-tracker = {
    enable = mkEnableOption "pr-tracker server container";

    image = mkImageOption "trev.zip/llc/pr-tracker/server:0.0.1@sha256:3b4d1d54a8e7b693dc792c9498ff106c6128d0930715f445c02c818874c4f7d7";

    domain = mkOption {
      type = types.str;
      default = "pr-tracker.trev.zip";
      description = "Domain routed to pr-tracker.";
    };

    signupEnabled = mkOption {
      type = types.bool;
      default = false;
      description = "Whether new pr-tracker accounts can be created.";
    };

    trustedProxyCIDRs = mkOption {
      type = types.listOf types.str;
      default = [ "10.10.10.105/32" ];
      description = "Proxy CIDRs allowed to set X-Forwarded-For.";
    };

    jwtSecret = mkOption {
      type = secretType;
      default = {
        ref = "pr-tracker-jwt";
        file = self + /secrets/pr-tracker-jwt.age;
      };
      description = "pr-tracker session signing secret.";
    };

    encryptionKeySecret = mkOption {
      type = secretType;
      default = {
        ref = "pr-tracker-encryption-key";
        file = self + /secrets/pr-tracker-encryption-key.age;
      };
      description = "pr-tracker secret used to encrypt saved forge API keys.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "pr-tracker";
      description = "Name of the persistent pr-tracker data volume.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      secrets = {
        ${cfg.jwtSecret.ref} = cfg.jwtSecret;
        ${cfg.encryptionKeySecret.ref} = cfg.encryptionKeySecret;
      };

      containers.pr-tracker.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        user = "65532";
        group = "65532";
        # The SQLite database lives under $XDG_CONFIG_HOME/pr-tracker.
        environments = {
          XDG_CONFIG_HOME = "/data";
          SIGNUP_ENABLED = boolToString cfg.signupEnabled;
          AUTH_COOKIE_SECURE = "true";
          TRUSTED_PROXY_CIDRS = concatStringsSep "," cfg.trustedProxyCIDRs;
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
          {
            inherit (cfg.encryptionKeySecret) ref;
            type = "env";
            target = "ENCRYPTION_KEY";
          }
        ];
        publishPorts = [ "8080" ];
        labels = {
          traefik = {
            enable = true;
            http.routers.pr-tracker = {
              rule = "Host(`${cfg.domain}`)";
              middlewares = "secure@file";
            };
          };
        };
      };

      volumes.${cfg.volumeName} = { };
    };
  };
}
