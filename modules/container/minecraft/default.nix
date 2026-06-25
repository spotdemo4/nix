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
      image = "docker.io/itzg/minecraft-server:latest@sha256:7fb066de722ad1b8dd05bb1681d68f7c89833c82990026ac084b515014b0aaa8";
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
        attrs.traefik = {
          enable = true;
          tcp.routers.minecraft = {
            rule = "HostSNI(`*`)";
            entryPoints = "minecraft";
          };
        };
      };
    };

    volumes = {
      allthemods10_2 = { };
    };
  };
}
