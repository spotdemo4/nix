{
  pkgs,
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
  mkSecret = (import ./utils/mkSecret.nix {inherit pkgs config;}).mkSecret;

  cfSecret = mkSecret "curseforge" config.age.secrets."curseforge".path;
in {
  age.secrets."curseforge".file = self + /secrets/curseforge.age;
  system.activationScripts = {
    "${cfSecret.ref}" = cfSecret.script;
  };

  virtualisation.quadlet = {
    containers.minecraft.containerConfig = {
      image = "docker.io/itzg/minecraft-server:latest@sha256:d5147f150bf6e5954b828783a31e9a77cac5f13ae9d89dccec3c6d709584d538";
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
        "${cfSecret.ref},type=env,target=CF_API_KEY"
      ];
      volumes = [
        "${volumes.allthemods10.ref}:/data"
      ];
      publishPorts = [
        "25565"
      ];
      labels = toLabel [] {
        traefik = {
          enable = true;
          tcp.routers.minecraft = {
            rule = "HostSNI(`*`)";
            entryPoints = "minecraft";
          };
        };
      };
    };

    volumes = {
      allthemods10 = {};
    };
  };
}
