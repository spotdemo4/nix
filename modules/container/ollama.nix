{
  pkgs,
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes networks;
  toLabel = import (self + /modules/util/label);

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
    export OLLAMA_NUM_CTX=32768
    export OLLAMA_CONTEXT_LENGTH=32768
    export IPEX_LLM_NUM_CTX=32768
    export OLLAMA_NUM_PARALLEL=1

    # start ollama service
    /llm/ollama/ollama serve
  '';
in {
  secrets."openwebui".file = self + /secrets/openwebui.age;

  virtualisation.quadlet = {
    containers = {
      ollama.containerConfig = {
        image = "docker.io/intelanalytics/ipex-llm-inference-cpp-xpu:latest@sha256:74c7fba6e12a083ff664ae54e1ff16a977a39caa03d272125db406eeddaee09e";
        pull = "missing";
        environments = {
          DEVICE = "Arc";
        };
        devices = [
          "/dev/dri/card1:/dev/dri/card1"
          "/dev/dri/renderD129:/dev/dri/renderD129"
        ];
        volumes = [
          "${volumes.ollama.ref}:/root/.ollama/models"
          "${start}:/start.sh"
        ];
        publishPorts = [
          "11434"
        ];
        networks = [
          networks.ipex-llm.ref
        ];
        labels = toLabel {
          attrs = {
            traefik = {
              enable = true;
              http.routers.ollama = {
                rule = "HostRegexp(`ollama.trev.(zip|kiwi)`)";
                middlewares = "auth-basic@file";
              };
            };
          };
        };
        entrypoint = "/start.sh";
      };

      open-webui.containerConfig = {
        image = "ghcr.io/open-webui/open-webui:main@sha256:f43e2e1ac4634bb26912c4cc1eb167f0431cabda8f65f2d2457a615def982fdc";
        pull = "missing";
        environments = {
          WEBUI_URL = "https://chat.trev.zip";
          WEBUI_AUTH_TRUSTED_EMAIL_HEADER = "X-Forwarded-Email";
          WEBUI_AUTH_TRUSTED_NAME_HEADER = "X-Forwarded-User";
          DEFAULT_USER_ROLE = "user";
          ENABLE_OLLAMA_API = "true";
          OLLAMA_BASE_URL = "http://ollama:11434/";
          ENABLE_OPENAI_API = "false";
          ENABLE_WEB_SEARCH = "true";
          WEB_SEARCH_ENGINE = "duckduckgo";
          ENABLE_IMAGE_GENERATION = "false";
          WHISPER_MODEL = "large";
        };
        secrets = [
          "${config.secrets."openwebui".env},target=OAUTH_CLIENT_SECRET"
        ];
        volumes = [
          "${volumes.open-webui.ref}:/app/backend/data"
        ];
        publishPorts = [
          "8080"
        ];
        networks = [
          networks.ipex-llm.ref
        ];
        labels = toLabel {
          attrs = {
            traefik = {
              enable = true;
              http.routers.open-webui = {
                rule = "HostRegexp(`chat.trev.(zip|kiwi)`)";
                middlewares = "auth-plex@docker";
              };
            };
          };
        };
      };
    };

    volumes = {
      ollama = {};
      open-webui = {};
    };

    networks = {
      ipex-llm = {};
    };
  };
}
