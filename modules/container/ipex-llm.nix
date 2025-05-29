{config, ...}: {
  virtualisation.quadlet = let
    utils = import ./utils.nix;
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    containers = {
      ipex-llm.containerConfig = {
        image = "docker.io/intelanalytics/ipex-llm-inference-cpp-xpu:latest";
        pull = "newer";
        autoUpdate = "registry";
        memory = "16G";
        shmSize = "16g";
        environments = {
          DEVICE = "Arc";
        };
        devices = [
          "/dev/dri/card1:/dev/dri/card1"
        ];
        volumes = [
          "${volumes.ipex-llm.ref}:/models"
        ];
        networks = [
          networks.ipex-llm.ref
        ];
        entrypoint = "/llm/scripts/start-ollama.sh";
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
          OPENAI_API_BASE_URL = "http://ipex-llm:11434/v1";
        };
        volumes = [
          "${volumes.open-webui.ref}:/app/backend/data"
        ];
        publishPorts = [
          "8080:8080"
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
      ipex-llm = {};
      open-webui = {};
    };

    networks = {
      ipex-llm = {};
    };
  };
}
