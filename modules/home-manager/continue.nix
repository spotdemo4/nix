{
  config,
  pkgs,
  self,
  ...
}:
let
  configFile = (pkgs.formats.yaml { }).generate "config.yaml" {
    name = "TrevChat";
    version = "0.0.1";
    schema = "v1";

    models = [
      {
        name = "QwenCoder";
        provider = "ollama";
        model = "qwen2.5-coder:14b";
        apiBase = "https://ollama.trev.zip";
        roles = [
          "autocomplete"
        ];
        requestOptions.headers.Authorization = "Basic \${{ secrets.token }}";
      }
      {
        name = "Deepseek R1";
        provider = "ollama";
        model = "deepseek-r1:14b";
        apiBase = "https://ollama.trev.zip";
        roles = [
          "chat"
          "edit"
        ];
        requestOptions.headers.Authorization = "Basic \${{ secrets.token }}";
      }
    ];

    context = [
      {
        provider = "http";
        name = "Context7";
        params = {
          url = "https://context7.trev.zip/mcp";
        };
      }
    ];
  };
in
{
  age.secrets."continue".file = self + /secrets/continue.age;
  age.secrets."continue".path = config.home.homeDirectory + "/.continue/.env";

  home.file.".continue/assistants/config.yaml".source = configFile;
}
