{
  self,
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /modules/util/label);
in
{
  secrets."curseforge".file = self + /secrets/curseforge.age;

  virtualisation.quadlet = {
    containers.minecraft.containerConfig = {
      image = "docker.io/itzg/minecraft-server:latest@sha256:e5b9b0664aff479fcf83132dc9d5d6fcca6d2544dc7c88cf87615b17ef064531";
      pull = "missing";
      environments = {
        EULA = "TRUE";
        TYPE = "AUTO_CURSEFORGE";
        CF_PAGE_URL = "https://www.curseforge.com/minecraft/modpacks/all-the-mods-10";
        MEMORY = "16G";
        ALLOW_FLIGHT = "true";
        MOTD = "chicken jockey";
      };
      secrets = [
        "${config.secrets."curseforge".env},target=CF_API_KEY"
      ];
      volumes = [
        "${volumes.allthemods10_2.ref}:/data"
      ];
      publishPorts = [
        "25565"
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            tcp.routers.minecraft = {
              rule = "HostSNI(`*`)";
              entryPoints = "minecraft";
            };
          };
        };
      };
    };

    volumes = {
      allthemods10_2 = { };
    };
  };
}
