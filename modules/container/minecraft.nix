{
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /modules/util/label);
in {
  secrets."curseforge".file = self + /secrets/curseforge.age;

  virtualisation.quadlet = {
    containers.minecraft.containerConfig = {
      image = "docker.io/itzg/minecraft-server:latest@sha256:fe099b1f2f8edac17d729a83af081a47742bb7744a6634365e9e99e82c9650ac";
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
        "${volumes.allthemods10.ref}:/data"
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
      allthemods10 = {};
    };
  };
}
