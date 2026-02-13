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
      image = "ghcr.io/open-webui/open-webui:main@sha256:f1c28d8f57ce1c759dd61351d5b90e30627cdebe6725ba45f4d02c432b7fd21b";
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
