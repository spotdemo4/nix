{config, ...}: {
  virtualisation.quadlet = let
    utils = import ./utils.nix;
    inherit (config.virtualisation.quadlet) volumes networks;
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
        # globalArgs = [
        #   "--log-level=debug"
        # ];
        devices = [
          "/dev/dri/card1:/dev/dri/card1"
        ];
        volumes = [
          "${volumes.ipex-llm_data.ref}:/models"
        ];
        networks = [
          networks.ipex-llm.ref
        ];
        entrypoint = "bash -c /llm/scripts/start-ollama.sh & wait";
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
