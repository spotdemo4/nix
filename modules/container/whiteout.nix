{
  pkgs,
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
  mkSecret = (import ./utils/mkSecret.nix {inherit pkgs config;}).mkSecret;

  secret = mkSecret "whiteout" config.age.secrets."whiteout".path;
in {
  age.secrets."whiteout".file = self + /secrets/whiteout.age;
  system.activationScripts = {
    "${secret.ref}" = secret.script;
  };

  virtualisation.quadlet = {
    containers.whiteout.containerConfig = {
      image = "docker.io/eilandert/whiteout-survival-discord-bot:main@sha256:6b016c1b7b083bfccec5fd9c85c169489627d252676593e884060eb2d2312fe4";
      pull = "missing";
      secrets = [
        "${secret.ref},type=env,target=DISCORD_BOT_TOKEN"
      ];
      volumes = [
        "${volumes.whiteout.ref}:/app/db"
      ];
    };

    volumes = {
      whiteout = {};
    };
  };
}
