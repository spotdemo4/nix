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
  cfg = config.trev.containers.minecraft;
in
{
  options.trev.containers.minecraft = {
    enable = mkEnableOption "the Minecraft container";
    image = mkImageOption "docker.io/itzg/minecraft-server:latest@sha256:0621a2aa4b3ee6eec07fe7ea554af1ee68b808c5b7aad62668e83bc5f4ff28e2";

    curseforgeSecret = mkOption {
      type = secretType;
      default = {
        ref = "curseforge";
        file = self + /secrets/curseforge.age;
      };
      description = "CurseForge API key secret.";
    };

    eula = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to accept the Minecraft EULA.";
    };

    type = mkOption {
      type = types.str;
      default = "AUTO_CURSEFORGE";
      description = "Minecraft server type.";
    };

    curseforgePageUrl = mkOption {
      type = types.str;
      default = "https://www.curseforge.com/minecraft/modpacks/all-the-mods-10";
      description = "CurseForge modpack page URL.";
    };

    memory = mkOption {
      type = types.str;
      default = "16G";
      description = "Memory allocated to the Minecraft server.";
    };

    allowFlight = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to allow flight on the Minecraft server.";
    };

    motd = mkOption {
      type = types.str;
      default = "chicken jockey";
      description = "Minecraft server message of the day.";
    };

    port = mkOption {
      type = types.port;
      default = 25565;
      description = "Minecraft port published on the host.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [ "${toString cfg.port}:25565" ];
      defaultText = lib.literalExpression ''[ "''${toString cfg.port}:25565" ]'';
      description = "Ports to publish from Minecraft.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "allthemods10_2";
      description = "Name of the persistent Minecraft data volume.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.minecraft = {
      protocol = "tcp";
      inherit (cfg) port;
      listen = 25565;
    };

    virtualisation.quadlet = {
      secrets.${cfg.curseforgeSecret.ref} = cfg.curseforgeSecret;

      containers.minecraft.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          EULA = lib.boolToString cfg.eula;
          TYPE = cfg.type;
          CF_PAGE_URL = cfg.curseforgePageUrl;
          MEMORY = cfg.memory;
          ALLOW_FLIGHT = lib.boolToString cfg.allowFlight;
          MOTD = cfg.motd;
        };
        secrets = [
          {
            inherit (cfg.curseforgeSecret) ref;
            type = "env";
            target = "CF_API_KEY";
          }
        ];
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/data"
        ];
        publishPorts = cfg.publishPorts;
      };

      volumes.${cfg.volumeName} = { };
    };
  };
}
