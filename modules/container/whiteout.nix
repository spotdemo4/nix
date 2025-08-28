{
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
in {
  secrets."whiteout".file = self + /secrets/whiteout.age;

  virtualisation.quadlet = {
    containers.whiteout.containerConfig = {
      image = "docker.io/eilandert/whiteout-survival-discord-bot:main@sha256:6b016c1b7b083bfccec5fd9c85c169489627d252676593e884060eb2d2312fe4";
      pull = "missing";
      secrets = [
        "${config.secrets."whiteout".env},target=DISCORD_BOT_TOKEN"
      ];
      volumes = [
        "${volumes.whiteout.ref}:/app/db"
      ];
      entrypoint = [
        "sh"
        "-c"
        "/bootstrap.sh || true && tail -f /dev/null"
      ];
    };

    volumes = {
      whiteout = {};
    };
  };
}
