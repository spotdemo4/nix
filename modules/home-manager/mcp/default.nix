{ self, config, ... }:
{
  programs.mcp = {
    enable = true;
    servers = {
      kagi = {
        url = "https://mcp.kagi.com/mcp";
        headers = {
          Authorization = "Bearer {env:KAGI_TOKEN}";
        };
      };
    };
  };

  age.secrets."kagi".file = self + /secrets/kagi.age;
  home.sessionVariables = {
    KAGI_TOKEN = "$(cat ${config.age.secrets."kagi".path})";
  };
}
