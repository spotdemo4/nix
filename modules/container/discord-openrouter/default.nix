{
  config,
  lib,
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
  inherit (config.virtualisation.quadlet)
    volumes
    ;
  cfg = config.trev.containers.discord-openrouter;
in
{
  options.trev.containers.discord-openrouter = {
    enable = mkEnableOption "Discord OpenRouter container";

    image = mkImageOption "ghcr.io/spotdemo4/discord-openrouter:0.0.9@sha256:f0f840513a644c65236d4b8eb3708d5aef3b4fdff3425dbbefba0d6c1a5a186b";

    openrouterSecret = mkOption {
      type = secretType;
      default = {
        ref = "openrouter";
        file = self + /secrets/openrouter.age;
      };
      description = "OpenRouter API key secret.";
    };

    discordSecret = mkOption {
      type = secretType;
      default = {
        ref = "discord-openrouter";
        file = self + /secrets/discord-openrouter.age;
      };
      description = "Discord bot token secret.";
    };

    databasePath = mkOption {
      type = types.str;
      default = "/data/data.db";
      description = "Database path inside the container.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      secrets = {
        ${cfg.openrouterSecret.ref} = cfg.openrouterSecret;
        ${cfg.discordSecret.ref} = cfg.discordSecret;
      };

      containers.discord-openrouter.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          DEFAULT_PROMPT = "don't worry about formalities. don't use emojis. don't be cringe. be as terse as possible while still conveying substantially all information relevant to any question. critique freely and avoid sycophancy. don't be afraid to take a side in any discussion, especially if one side is clearly correct. cite sources for your claims if possible. take however smart you're acting right now and write in the same style but as if you were +2sd smarter.";
          DB_PATH = cfg.databasePath;
          DEFAULT_MODEL = "google/gemini-2.5-flash";
        };
        secrets = [
          {
            inherit (cfg.openrouterSecret) ref;
            type = "env";
            target = "OPENROUTER_API_KEY";
          }
          {
            inherit (cfg.discordSecret) ref;
            type = "env";
            target = "DISCORD_TOKEN";
          }
        ];
        volumes = [
          "${volumes.discord-openrouter.ref}:/data"
        ];
      };

      volumes.discord-openrouter = { };
    };
  };
}
