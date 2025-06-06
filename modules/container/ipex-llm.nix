{
  pkgs,
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes networks;
  toLabel = (import ./utils/toLabel.nix).toLabel;
  mkSecret = (import ./utils/mkSecret.nix {inherit pkgs config;}).mkSecret;

  owuiSecret = mkSecret "openwebui" config.age.secrets.openwebui.path;
  start = pkgs.writeScript "start.sh" ''
    #!/bin/sh

    # init ollama
    source ipex-llm-init --gpu --device $DEVICE
    mkdir -p /llm/ollama
    cd /llm/ollama
    init-ollama
    export OLLAMA_NUM_GPU=999
    export ZES_ENABLE_SYSMAN=1
    export OLLAMA_HOST=0.0.0.0:11434

    # start ollama service
    /llm/ollama/ollama serve
  '';
in {
  age.secrets."openwebui".file = self + /secrets/openwebui.age;
  system.activationScripts = {
    "${owuiSecret.ref}" = owuiSecret.script;
  };

  virtualisation.quadlet = {
    containers = {
      ipex-llm-ollama.containerConfig = {
        image = "docker.io/intelanalytics/ipex-llm-inference-cpp-xpu:latest";
        pull = "newer";
        autoUpdate = "registry";
        # memory = "16G";
        # shmSize = "16g";
        environments = {
          DEVICE = "Arc";
        };
        devices = [
          "/dev/dri/card1:/dev/dri/card1"
          "/dev/dri/renderD129:/dev/dri/renderD129"
        ];
        volumes = [
          "${volumes.ipex-llm_data.ref}:/root/.ollama/models"
          "${start}:/start.sh"
        ];
        publishPorts = [
          "11434"
        ];
        networks = [
          networks.ipex-llm.ref
        ];
        labels = toLabel [] {
          traefik = {
            enable = true;
            http = {
              routers.ollama = {
                rule = "Host(`ollama.trev.zip`)";
                entryPoints = "https";
                tls.certresolver = "letsencrypt";
                middlewares = "auth-basic@docker";
              };
            };
          };
        };
        entrypoint = "/start.sh";
      };

      open-webui.containerConfig = {
        image = "ghcr.io/open-webui/open-webui:main";
        pull = "newer";
        autoUpdate = "registry";
        environments = {
          WEBUI_URL = "https://chat.trev.zip";
          ENABLE_OLLAMA_API = "true";
          OLLAMA_BASE_URL = "http://ipex-llm-ollama:11434/";
          ENABLE_OPENAI_API = "false";
          ENABLE_WEB_SEARCH = "true";
          WEB_SEARCH_ENGINE = "duckduckgo";
          ENABLE_IMAGE_GENERATION = "false";
          WHISPER_MODEL = "large";
        };
        secrets = [
          "${owuiSecret.ref},type=env,target=OAUTH_CLIENT_SECRET"
        ];
        volumes = [
          "${volumes.open-webui_data.ref}:/app/backend/data"
        ];
        publishPorts = [
          "8080"
        ];
        networks = [
          networks.ipex-llm.ref
        ];
        labels = toLabel [] {
          traefik = {
            enable = true;
            http.routers.open-webui = {
              rule = "Host(`chat.trev.zip`)";
              entryPoints = "https";
              tls.certresolver = "letsencrypt";
              middlewares = "auth-github@docker";
            };
          };
        };
      };
    };

    volumes = {
      ipex-llm_data = {};
      open-webui_data = {};
    };

    networks = {
      ipex-llm = {};
    };
  };
}
