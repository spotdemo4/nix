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
        name = "Ollama";
        provider = "ollama";
        model = "qwen2.5-coder:1.5b";
        apiBase = "https://ollama.trev.zip";
        roles = [
          "autocomplete"
        ];
        defaultCompletionOptions = {
          temperature = "0.3";
          stop = "\n";
        };
        requestOptions.headers.Authorization = "Basic \${{ secrets.token }}";
      }
    ];
  };
in {
  age.secrets."authelia-env".file = self + /secrets/authelia-env.age;
  age.secrets."authelia-env".path = config.home.homeDirectory + "/.continue/.env";

  home.file.".continue/assistants/config.yaml".source = configFile;
}
