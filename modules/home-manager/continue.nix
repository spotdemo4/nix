{
  config,
  pkgs,
  self,
  ...
}: let
  configFile = (pkgs.formats.yaml {}).generate "config.yaml" {
    name = "TrevChat";
    version = "0.0.1";
    schema = "v1";

    models = [
      {
        name = "QwenCoder";
        provider = "ollama";
        model = "qwen2.5-coder:1.5b";
        apiBase = "https://ollama.trev.zip";
        roles = [
          "autocomplete"
        ];
        requestOptions.headers.Authorization = "Basic \${{ secrets.token }}";
      }
      {
        name = "Gemma3";
        provider = "ollama";
        model = "gemma3:4b";
        apiBase = "https://ollama.trev.zip";
        roles = [
          "chat"
          "edit"
        ];
        requestOptions.headers.Authorization = "Basic \${{ secrets.token }}";
      }
      {
        name = "Deepseek R1";
        provider = "ollama";
        model = "deepseek-r1:8b";
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
in {
  age.secrets."auth-basic-env".file = self + /secrets/auth-basic-env.age;
  age.secrets."auth-basic-env".path = config.home.homeDirectory + "/.continue/.env";

  home.file.".continue/assistants/config.yaml".source = configFile;
}
