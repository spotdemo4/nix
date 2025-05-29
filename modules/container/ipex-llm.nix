{
  pkgs,
  config,
  ...
}: {
  virtualisation.quadlet = let
    utils = import ./utils.nix;
    inherit (config.virtualisation.quadlet) volumes networks;

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
          "${volumes.ipex-llm_data.ref}:/models"
          "${start}:/start.sh"
        ];
        publishPorts = [
          "11434:11434"
        ];
        networks = [
          networks.ipex-llm.ref
        ];
        labels = utils.toEnvStrings [] {
          traefik = {
            enable = true;
            http.routers.ollama = {
              rule = "Host(`ollama.trev.zip`)";
              entryPoints = "https";
              tls.certresolver = "letsencrypt";
              middlewares = "authelia@docker";
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
          ENABLE_RAG_WEB_SEARCH = "true";
          RAG_WEB_SEARCH_ENGINE = "duckduckgo";
          ENABLE_OLLAMA_API = "false";
          ENABLE_IMAGE_GENERATION = "false";
          WHISPER_MODEL = "large";
          OPENAI_API_BASE_URL = "http://ipex-llm-ollama:11434/v1";
        };
        volumes = [
          "${volumes.open-webui_data.ref}:/app/backend/data"
        ];
        publishPorts = [
          "8000:8080"
        ];
        networks = [
          networks.ipex-llm.ref
        ];
        labels = utils.toEnvStrings [] {
          traefik = {
            enable = true;
            http.routers.open-webui = {
              rule = "Host(`chat.trev.zip`)";
              entryPoints = "https";
              tls.certresolver = "letsencrypt";
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
