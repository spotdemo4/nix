{
  config,
  lib,
  self,
  pkgs,
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

  catppuccinTheme = pkgs.callPackage ./theme.nix { };
in
{
  options.trev.containers.forgejo = {
    enable = mkEnableOption "Forgejo container";
    image = mkImageOption "codeberg.org/forgejo/forgejo:16.0.5@sha256:cf5f5ae6acf2ababca0ee3d255705b83a47f35b25e07fc931d694d60664053fe";

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

    routed = mkOption {
      type = types.bool;
      default = true;
      description = "Whether trev-proxy routes the domain straight to Forgejo; disable when Anubis fronts it.";
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
    trev.proxy.routes.forgejo = mkIf cfg.routed {
      domains = [ cfg.domain ];
      inherit (cfg) port;
    };

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
          "${volumes.forgejo-archive-cache.ref}:/data/gitea/repo-archive"
          "${./app.ini}:/data/gitea/conf/app.ini"
          "${catppuccinTheme}:/data/gitea/public/assets/css:ro"
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
          "${toString cfg.port}:3000"
        ];
        networks = [
          networks.forgejo.ref
        ];
      };

      volumes = {
        forgejo = { };
        forgejo-archive-cache.volumeConfig = {
          copy = false;
          # Podman 5.8 supports these flags but not Quadlet's UID/GID keys.
          podmanArgs = [
            "--uid=1000"
            "--gid=1000"
          ];
        };
      };
      networks.forgejo = { };
    };
  };
}
