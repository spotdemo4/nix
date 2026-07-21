{
  lib,
  config,
  self,
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
  cfg = config.trev.containers.discord-embedder;
  inherit (config.virtualisation.quadlet) volumes;
in
{
  options.trev.containers.discord-embedder = {
    enable = mkEnableOption "Discord embedder container";
    image = mkImageOption "ghcr.io/spotdemo4/discord-embedder:0.1.23@sha256:69f4ff92dd35fd186e4005a648fa1d0ca650bb89c97d00610eb9f83c14b0b805";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Discord embedder.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Discord embedder.";
    };
    devices = mkOption {
      type = types.listOf types.str;
      default = [
        "/dev/dri/card0:/dev/dri/card0"
        "/dev/dri/renderD128:/dev/dri/renderD128"
      ];
      description = "Host devices exposed to Discord embedder.";
    };
    filesPath = mkOption {
      type = types.str;
      default = "/mnt/pool/memes";
      description = "Host path containing files served by Discord embedder.";
    };
    publicUrl = mkOption {
      type = types.str;
      default = "https://embed.trev.xyz";
      description = "Public URL advertised by Discord embedder.";
    };
    domainPattern = mkOption {
      type = types.str;
      default = "embed.trev.(xyz|zip|kiwi)";
      description = "Traefik HostRegexp pattern for Discord embedder.";
    };
    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Discord embedder port published on the host.";
    };
    discordApplicationId = mkOption {
      type = types.str;
      default = "1279604203001610260";
      description = "Discord application ID.";
    };
    discordChannelIds = mkOption {
      type = types.str;
      default = "150459222637805570";
      description = "Comma-separated Discord channel IDs.";
    };
    discordSecret = mkOption {
      type = secretType;
      default = {
        ref = "embedder-discord";
        file = self + /secrets/embedder-discord.age;
      };
      description = "Discord token secret.";
    };
    instagramSecret = mkOption {
      type = secretType;
      default = {
        ref = "embedder-instagram";
        file = self + /secrets/embedder-instagram.age;
      };
      description = "Instagram password secret.";
    };
    redditSecret = mkOption {
      type = secretType;
      default = {
        ref = "embedder-reddit";
        file = self + /secrets/embedder-reddit.age;
      };
      description = "Reddit password secret.";
    };
    tiktokSecret = mkOption {
      type = secretType;
      default = {
        ref = "embedder-tiktok";
        file = self + /secrets/embedder-tiktok.age;
      };
      description = "TikTok password secret.";
    };
    xSecret = mkOption {
      type = secretType;
      default = {
        ref = "embedder-x";
        file = self + /secrets/embedder-x.age;
      };
      description = "X password secret.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      secrets = {
        ${cfg.discordSecret.ref} = cfg.discordSecret;
        ${cfg.instagramSecret.ref} = cfg.instagramSecret;
        ${cfg.redditSecret.ref} = cfg.redditSecret;
        ${cfg.tiktokSecret.ref} = cfg.tiktokSecret;
        ${cfg.xSecret.ref} = cfg.xSecret;
      };

      containers.discord-embedder.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        user = "${toString cfg.uid}:${toString cfg.gid}";
        devices = cfg.devices;
        environments = {
          DISCORD_APPLICATION_ID = cfg.discordApplicationId;
          DISCORD_CHANNEL_IDS = cfg.discordChannelIds;
          FILES_DIR = "/files";
          TMP_DIR = "/tmp";
          HOST = cfg.publicUrl;
          PORT = toString cfg.port;
          QUICKSYNC = "true";
          INSTAGRAM_USERNAME = "spam@trev.xyz";
          REDDIT_USERNAME = "spotemo7";
          TIKTOK_USERNAME = "embedder@trev.xyz";
          X_USERNAME = "embedder@trev.xyz";
        };
        secrets = [
          {
            inherit (cfg.discordSecret) ref;
            type = "env";
            target = "DISCORD_TOKEN";
          }
          {
            inherit (cfg.instagramSecret) ref;
            type = "env";
            target = "INSTAGRAM_PASSWORD";
          }
          {
            inherit (cfg.redditSecret) ref;
            type = "env";
            target = "REDDIT_PASSWORD";
          }
          {
            inherit (cfg.tiktokSecret) ref;
            type = "env";
            target = "TIKTOK_PASSWORD";
          }
          {
            inherit (cfg.xSecret) ref;
            type = "env";
            target = "X_PASSWORD";
          }
        ];
        volumes = [
          "${cfg.filesPath}:/files"
          "${volumes.discord-embedder.ref}:/tmp"
        ];
        publishPorts = [ (toString cfg.port) ];
        labels = {
          traefik = {
            enable = true;
            http.routers.embed.rule = "HostRegexp(`${cfg.domainPattern}`)";
          };
        };
      };

      volumes.discord-embedder = { };
    };
  };
}
