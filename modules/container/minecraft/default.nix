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
    secretReferenceType
    ;
  cfg = config.trev.containers.minecraft;
  inherit (config.virtualisation.quadlet) volumes;
in
{
  options.trev.containers.minecraft = {
    enable = mkEnableOption "the Minecraft container";
    image = mkImageOption "docker.io/itzg/minecraft-server:latest@sha256:9faa6aefeedd5a883c3ee241653fd1421529bdbafc428d0513e43cae0f2b7d68";

    curseforgeSecret = mkOption {
      type = secretReferenceType;
      default = {
        ref = "curseforge";
        file = self + /secrets/curseforge.age;
      };
      description = "CurseForge API key secret.";
    };

    environments = mkOption {
      type = types.attrsOf types.str;
      default = {
        EULA = "TRUE";
        TYPE = "AUTO_CURSEFORGE";
        CF_PAGE_URL = "https://www.curseforge.com/minecraft/modpacks/all-the-mods-10";
        MEMORY = "16G";
        ALLOW_FLIGHT = "true";
        MOTD = "chicken jockey";
      };
      description = "Environment variables passed to the Minecraft server.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [ "25565" ];
      description = "Ports to publish from Minecraft.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "allthemods10_2";
      description = "Name of the persistent Minecraft data volume.";
    };
  };

  config = mkIf cfg.enable {
    secrets.${cfg.curseforgeSecret.ref}.file = toString cfg.curseforgeSecret.file;

    virtualisation.quadlet = {
      containers.minecraft.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = cfg.environments;
        secrets = [
          "${cfg.curseforgeSecret.env},target=CF_API_KEY"
        ];
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/data"
        ];
        publishPorts = cfg.publishPorts;
        labels = {
          traefik = {
            enable = true;
            tcp.routers.minecraft = {
              rule = "HostSNI(`*`)";
              entryPoints = "minecraft";
            };
          };
        };
      };

      volumes.${cfg.volumeName} = { };
    };
  };
}
