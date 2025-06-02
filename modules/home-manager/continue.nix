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
        name = "Llama";
        provider = "ollama";
        model = "llama3.1:8b";
        apiBase = "https://ollama.trev.zip";
        roles = [
          "chat"
          "edit"
        ];
        requestOptions.headers.Authorization = "Basic \${{ secrets.token }}";
      }
    ];
  };
in {
  age.secrets."authelia-env".file = self + /secrets/authelia-env.age;
  age.secrets."authelia-env".path = config.home.homeDirectory + "/.continue/.env";

  home.file.".continue/assistants/config.yaml".source = configFile;
}
