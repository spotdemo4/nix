{
  config,
  lib,
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
    networks
    volumes
    ;
  cfg = config.trev.containers.forgejo;
in
{
  options.trev.containers.forgejo = {
    enable = mkEnableOption "Forgejo container";
    image = mkImageOption "codeberg.org/forgejo/forgejo:16.0.1@sha256:3eb3107bc9de4e9d6d9e539044e6c802dc0b7be351919a145540d4cb5422bf07";

    domain = mkOption {
      type = types.str;
      default = "trev.zip";
      description = "Domain routed to Forgejo.";
    };

    localtimePath = mkOption {
      type = types.str;
      default = "/etc/localtime";
      description = "Host localtime file mounted into Forgejo.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Forgejo HTTP port to publish.";
    };

    lfsSecret = mkOption {
      type = secretType;
      default = {
        ref = "forgejo-lfs";
        file = self + /secrets/forgejo-lfs.age;
      };
      description = "Forgejo LFS JWT secret.";
    };
    jwtSecret = mkOption {
      type = secretType;
      default = {
        ref = "forgejo-jwt";
        file = self + /secrets/forgejo-jwt.age;
      };
      description = "Forgejo JWT secret.";
    };
    tokenSecret = mkOption {
      type = secretType;
      default = {
        ref = "forgejo-token";
        file = self + /secrets/forgejo-token.age;
      };
      description = "Forgejo internal token secret.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      secrets = {
        ${cfg.lfsSecret.ref} = cfg.lfsSecret;
        ${cfg.jwtSecret.ref} = cfg.jwtSecret;
        ${cfg.tokenSecret.ref} = cfg.tokenSecret;
      };

      containers.forgejo.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${volumes.forgejo.ref}:/data"
          "${volumes.forgejo-repo-archive.ref}:/data/gitea/repo-archive"
          "${./app.ini}:/data/gitea/conf/app.ini"
          "${cfg.localtimePath}:/etc/localtime:ro"
        ];
        secrets = [
          {
            inherit (cfg.lfsSecret) ref;
            type = "mount";
            target = "/secrets/forgejo-lfs";
          }
          {
            inherit (cfg.jwtSecret) ref;
            type = "mount";
            target = "/secrets/forgejo-jwt";
          }
          {
            inherit (cfg.tokenSecret) ref;
            type = "mount";
            target = "/secrets/forgejo-token";
          }
        ];
        publishPorts = [
          (toString cfg.port)
        ];
        networks = [
          networks.forgejo.ref
        ];
        labels = {
          traefik = {
            enable = true;
            http.routers.forgejo = {
              rule = "Host(`${cfg.domain}`)";
              middlewares = "secure@file";
            };
          };
        };
      };

      volumes = {
        forgejo = { };
        forgejo-repo-archive.volumeConfig = {
          copy = false;
          device = "tmpfs";
          type = "tmpfs";
          options = "size=2G,uid=1000,gid=1000,mode=0750,nodev,nosuid,noexec";
        };
      };
      networks.forgejo = { };
    };
  };
}
