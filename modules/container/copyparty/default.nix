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
    volumes
    ;
  cfg = config.trev.containers.copyparty;

  accounts = "/accounts.conf";
  configFile = pkgs.replaceVars ./copyparty.conf {
    accounts = accounts;
  };
in
{
  options.trev.containers.copyparty = {
    enable = mkEnableOption "Copyparty container";
    image = mkImageOption "ghcr.io/9001/copyparty-ac:1.20.19@sha256:74e20a95ed1e7146c2d3e970a6fc4279066dadb1b3d6816ab4b0d331403d230a";

    dataPath = mkOption {
      type = types.str;
      default = "/mnt/files";
      description = "Host path containing files served by Copyparty.";
    };

    domain = mkOption {
      type = types.str;
      default = "files.trev.zip";
      description = "Domain routed to Copyparty.";
    };

    accountsSecret = mkOption {
      type = secretType;
      default = {
        ref = "copyparty";
        file = self + /secrets/copyparty.age;
      };
      description = "Copyparty accounts configuration secret.";
    };

    userId = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Copyparty.";
    };

    groupId = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Copyparty.";
    };

    port = mkOption {
      type = types.port;
      default = 3923;
      description = "Copyparty HTTP port to publish.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      secrets.${cfg.accountsSecret.ref} = cfg.accountsSecret;

      containers.copyparty.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        user = "${toString cfg.userId}:${toString cfg.groupId}";
        secrets = [
          {
            inherit (cfg.accountsSecret) ref;
            type = "mount";
            target = accounts;
          }
        ];
        volumes = [
          "${cfg.dataPath}:/w"
          "${configFile}:/cfg/copyparty.conf"
          "${volumes.copyparty.ref}:/db"
        ];
        publishPorts = [
          (toString cfg.port)
        ];
        labels = {
          traefik = {
            enable = true;
            http.routers.copyparty = {
              rule = "Host(`${cfg.domain}`)";
              middlewares = "secure@file";
            };
          };
        };
      };

      volumes.copyparty = { };
    };
  };
}
