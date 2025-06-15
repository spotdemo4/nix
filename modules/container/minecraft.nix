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
      image = "docker.io/itzg/minecraft-server:latest";
      pull = "newer";
      autoUpdate = "registry";
      environments = {
        EULA = "TRUE";
        TYPE = "AUTO_CURSEFORGE";
        CF_PAGE_URL = "https://www.curseforge.com/minecraft/modpacks/all-the-mods-10";
        MEMORY = "8G";
      };
      secrets = [
        "${cfSecret.ref},type=env,target=CF_API_KEY"
      ];
      volumes = [
        "${volumes.minecraft.ref}:/data"
      ];
      publishPorts = [
        "25565"
      ];
      labels = toLabel [] {
        traefik = {
          enable = true;
          tcp.routers.minecraft = {
            rule = "HostSNIRegexp(`mc.trev.(zip|kiwi)`)";
            entryPoints = "minecraft";
          };
        };
      };
    };

    volumes = {
      minecraft = {};
    };
  };
}
