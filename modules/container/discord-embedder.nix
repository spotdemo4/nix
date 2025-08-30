{
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /modules/util/label);
in {
  secrets = {
    "embedder-discord".file = self + /secrets/embedder-discord.age;
    "embedder-instagram".file = self + /secrets/embedder-instagram.age;
    "embedder-reddit".file = self + /secrets/embedder-reddit.age;
    "embedder-tiktok".file = self + /secrets/embedder-tiktok.age;
    "embedder-x".file = self + /secrets/embedder-x.age;
  };

  virtualisation.quadlet = {
    containers.discord-embedder.containerConfig = {
      image = "ghcr.io/spotdemo4/discord-embedder:0.1.7@sha256:a5085cfe86204727321233a3acbbd01d0e81371732a9344084f689586c61daf4";
      pull = "missing";
      environments = {
        DISCORD_APPLICATION_ID = "1279604203001610260";
        DISCORD_CHANNEL_IDS = "150459222637805570";
        FILES_DIR = "/files";
        TMP_DIR = "/tmp";
        HOST = "https://embed.trev.xyz";
        PORT = "8080";
        QUICKSYNC = "true";

        INSTAGRAM_USERNAME = "spam@trev.xyz";
        REDDIT_USERNAME = "spotemo7";
        TIKTOK_USERNAME = "embedder@trev.xyz";
        X_USERNAME = "embedder@trev.xyz";
      };
      secrets = [
        "${config.secrets."embedder-discord".env},target=DISCORD_TOKEN"
        "${config.secrets."embedder-instagram".env},target=INSTAGRAM_PASSWORD"
        "${config.secrets."embedder-reddit".env},target=REDDIT_PASSWORD"
        "${config.secrets."embedder-tiktok".env},target=TIKTOK_PASSWORD"
        "${config.secrets."embedder-x".env},target=X_PASSWORD"
      ];
      volumes = [
        # "/mnt/pool/memes:/files"
        "${volumes.discord-embedder-test.ref}:/files"
        "${volumes.discord-embedder.ref}:/tmp"
      ];
      publishPorts = [
        "8080"
      ];
      devices = [
        "/dev/dri/card0:/dev/dri/card0"
        "/dev/dri/renderD128:/dev/dri/renderD128"
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.embed = {
              rule = "HostRegexp(`embed.trev.(xyz|zip|kiwi)`)";
            };
          };
        };
      };
    };

    volumes = {
      discord-embedder = {};
      discord-embedder-test = {};
    };
  };
}
