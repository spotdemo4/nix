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
    export OLLAMA_NUM_CTX=32768
    export OLLAMA_CONTEXT_LENGTH=32768
    export IPEX_LLM_NUM_CTX=32768
    export OLLAMA_NUM_PARALLEL=1

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
      ollama.containerConfig = {
        image = "docker.io/intelanalytics/ipex-llm-inference-cpp-xpu:latest@sha256:be3c8142f88b09ed182ed20d05487bd3ca4baa2f6b60523cb76718e7f1f47706";
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
        labels = toLabel [] {
          traefik = {
            enable = true;
            http.routers.ollama = {
              rule = "HostRegexp(`ollama.trev.(zip|kiwi)`)";
              middlewares = "auth-basic@file";
            };
          };
        };
        entrypoint = "/start.sh";
      };

      open-webui.containerConfig = {
        image = "ghcr.io/open-webui/open-webui:main@sha256:9c7cc3c9ea895fe362dac92b928d5e11ea901500c37d193642facebc3f513ff0";
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
          "${owuiSecret.ref},type=env,target=OAUTH_CLIENT_SECRET"
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
        labels = toLabel [] {
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

    volumes = {
      ollama = {};
      open-webui = {};
    };

    networks = {
      ipex-llm = {};
    };
  };
}
