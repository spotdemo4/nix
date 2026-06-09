{ self, config, ... }:
{
  programs.codex = {
    enable = true;
    settings = fromTOML (builtins.readFile ./config.toml);
  };

  age.secrets."kagi".file = self + /secrets/kagi.age;
  home.sessionVariables = {
    KAGI_TOKEN = "$(cat ${config.age.secrets."kagi".path})";
  };
}
