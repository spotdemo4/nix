{
  pkgs,
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
  mkSecret = (import ./utils/mkSecret.nix {inherit pkgs config;}).mkSecret;

  orSecret = mkSecret "openrouter" config.age.secrets."openrouter".path;
  discordSecret = mkSecret "discord-openrouter" config.age.secrets."discord-openrouter".path;
in {
  age.secrets."openrouter".file = self + /secrets/openrouter.age;
  age.secrets."discord-openrouter".file = self + /secrets/discord-openrouter.age;
  system.activationScripts = {
    "${orSecret.ref}" = orSecret.script;
    "${discordSecret.ref}" = discordSecret.script;
  };

  virtualisation.quadlet = {
    containers.discord-openrouter.containerConfig = {
      image = "ghcr.io/spotdemo4/discord-openrouter:0.0.8@sha256:d2ba2920a023ee2eb410625d2a8a2ca1c76615479f6bc52a53c296f7eb6a71c0";
      pull = "missing";
      environments = {
        DEFAULT_PROMPT = "don't worry about formalities. don't use emojis. don't be cringe. be as terse as possible while still conveying substantially all information relevant to any question. critique freely and avoid sycophancy. don't be afraid to use profanity, especially to convey frustration or intensity. don't be afraid to take a side in any discussion, especially if one side is clearly correct. cite sources for your claims if possible. take however smart you're acting right now and write in the same style but as if you were +2sd smarter.";
        DB_PATH = "/data/data.db";
      };
      secrets = [
        "${orSecret.ref},type=env,target=OPENROUTER_API_KEY"
        "${discordSecret.ref},type=env,target=DISCORD_TOKEN"
      ];
      volumes = [
        "${volumes.discord-openrouter.ref}:/data"
      ];
    };

    volumes = {
      discord-openrouter = {};
    };
  };
}
