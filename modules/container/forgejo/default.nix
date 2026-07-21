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
    image = mkImageOption "codeberg.org/forgejo/forgejo:15.0.5@sha256:eda2e378442d2f18cfa563994f8ad66e71f04ac9c3bb4259cc57bdd641890f5c";

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

      volumes.forgejo = { };
      networks.forgejo = { };
    };
  };
}
