{
  self,
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /modules/util/label);
in
{
  secrets."openwebui".file = self + /secrets/openwebui.age;

  virtualisation.quadlet = {
    containers.open-webui.containerConfig = {
      image = "ghcr.io/open-webui/open-webui:main@sha256:fa5747ca0e121c83be4f8e86e61ad7d2ca2c22c9cc4e0e7c541d9e13f967de10";
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
        "${volumes."open-webui".ref}:/app/backend/data"
      ];
      publishPorts = [
        "8080"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.open-webui = {
            rule = "Host(`chat.trev.xyz`)";
            middlewares = "secure-admin@file";
          };
        };
      };
    };

    volumes = {
      open-webui = { };
    };
  };
}
