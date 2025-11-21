{
  self,
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes;
in
{
  secrets = {
    "openrouter".file = self + /secrets/openrouter.age;
    "discord-openrouter".file = self + /secrets/discord-openrouter.age;
  };

  virtualisation.quadlet = {
    containers.discord-openrouter.containerConfig = {
      image = "ghcr.io/spotdemo4/discord-openrouter:0.0.9@sha256:f0f840513a644c65236d4b8eb3708d5aef3b4fdff3425dbbefba0d6c1a5a186b";
      pull = "missing";
      environments = {
        DEFAULT_PROMPT = "don't worry about formalities. don't use emojis. don't be cringe. be as terse as possible while still conveying substantially all information relevant to any question. critique freely and avoid sycophancy. don't be afraid to take a side in any discussion, especially if one side is clearly correct. cite sources for your claims if possible. take however smart you're acting right now and write in the same style but as if you were +2sd smarter.";
        DB_PATH = "/data/data.db";
        DEFAULT_MODEL = "google/gemini-2.5-flash";
      };
      secrets = [
        "${config.secrets."openrouter".env},target=OPENROUTER_API_KEY"
        "${config.secrets."discord-openrouter".env},target=DISCORD_TOKEN"
      ];
      volumes = [
        "${volumes.discord-openrouter.ref}:/data"
      ];
    };

    volumes = {
      discord-openrouter = { };
    };
  };
}
