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
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.discord-embedder;
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /lib/label);
  secretFileType = types.either types.path types.str;
in
{
  options.trev.containers.discord-embedder = {
    enable = mkEnableOption "Discord embedder container";
    image = containerOptions.mkImageOption "ghcr.io/spotdemo4/discord-embedder:0.1.23@sha256:69f4ff92dd35fd186e4005a648fa1d0ca650bb89c97d00610eb9f83c14b0b805";
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
    discordSecretFile = mkOption {
      type = secretFileType;
      default = self + /secrets/embedder-discord.age;
      description = "Age file containing the Discord token.";
    };
    instagramSecretFile = mkOption {
      type = secretFileType;
      default = self + /secrets/embedder-instagram.age;
      description = "Age file containing the Instagram password.";
    };
    redditSecretFile = mkOption {
      type = secretFileType;
      default = self + /secrets/embedder-reddit.age;
      description = "Age file containing the Reddit password.";
    };
    tiktokSecretFile = mkOption {
      type = secretFileType;
      default = self + /secrets/embedder-tiktok.age;
      description = "Age file containing the TikTok password.";
    };
    xSecretFile = mkOption {
      type = secretFileType;
      default = self + /secrets/embedder-x.age;
      description = "Age file containing the X password.";
    };
  };

  config = mkIf cfg.enable {
    secrets = {
      embedder-discord.file = cfg.discordSecretFile;
      embedder-instagram.file = cfg.instagramSecretFile;
      embedder-reddit.file = cfg.redditSecretFile;
      embedder-tiktok.file = cfg.tiktokSecretFile;
      embedder-x.file = cfg.xSecretFile;
    };

    virtualisation.quadlet = {
      containers.discord-embedder.containerConfig = {
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
          "${config.secrets.embedder-discord.env},target=DISCORD_TOKEN"
          "${config.secrets.embedder-instagram.env},target=INSTAGRAM_PASSWORD"
          "${config.secrets.embedder-reddit.env},target=REDDIT_PASSWORD"
          "${config.secrets.embedder-tiktok.env},target=TIKTOK_PASSWORD"
          "${config.secrets.embedder-x.env},target=X_PASSWORD"
        ];
        volumes = [
          "${cfg.filesPath}:/files"
          "${volumes.discord-embedder.ref}:/tmp"
        ];
        publishPorts = [ (toString cfg.port) ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.embed.rule = "HostRegexp(`${cfg.domainPattern}`)";
          };
        };
      };

      volumes.discord-embedder = { };
    };
  };
}
