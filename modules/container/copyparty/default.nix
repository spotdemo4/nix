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
    ;
  cfg = config.trev.containers.copyparty;
  inherit (config.virtualisation.quadlet) volumes;
  inherit (config) secrets;

  accounts = "/accounts.conf";
  configFile = pkgs.replaceVars ./copyparty.conf {
    accounts = accounts;
  };
in
{
  options.trev.containers.copyparty = {
    enable = mkEnableOption "Copyparty container";
    image = mkImageOption "ghcr.io/9001/copyparty-ac:1.20.18@sha256:59fe48c65b5f527c98abf0dfb9eb59e4177923c6a97287974524a6dacc0dbea7";

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

    accountsSecretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/copyparty.age;
      description = "Age-encrypted Copyparty accounts configuration.";
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
    secrets.copyparty.file = cfg.accountsSecretFile;

    virtualisation.quadlet = {
      containers.copyparty.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        user = "${toString cfg.userId}:${toString cfg.groupId}";
        secrets = [
          "${secrets.copyparty.mount},target=${accounts}"
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
