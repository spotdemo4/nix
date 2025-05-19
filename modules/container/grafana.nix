{pkgs, ...}: let
  utils = import ./utils.nix;
in {
  inherit (utils.mkVolume "grafana_data");

  virtualisation.oci-containers.containers = {
    grafana = {
      image = "grafana/grafana-enterprise:latest";
      pull = "newer";
      environment = {
        GF_SERVER_ROOT_URL = "https://grafana.trev.zip";
        # GF_AUTH_GENERIC_OAUTH_ENABLED = "false";
        # GF_AUTH_GENERIC_OAUTH_NAME = "Authelia";
        # GF_AUTH_GENERIC_OAUTH_ICON = "signin";
        # GF_AUTH_GENERIC_OAUTH_CLIENT_ID = "pmdxrEV_TTNxQe3FwL9yfybbuFNLdbUjfBpOU5kSczmEfMkQPlAvpormWW~xIQNsf17JeJ5x";
        # GF_AUTH_GENERIC_OAUTH_SCOPES = "openid profile email groups";
        # GF_AUTH_GENERIC_OAUTH_EMPTY_SCOPES = "false";
        # GF_AUTH_GENERIC_OAUTH_AUTH_URL = "https://auth.trev.zip/api/oidc/authorization";
        # GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "https://auth.trev.zip/api/oidc/token";
        # GF_AUTH_GENERIC_OAUTH_API_URL = "https://auth.trev.zip/api/oidc/userinfo";
        # GF_AUTH_GENERIC_OAUTH_LOGIN_ATTRIBUTE_PATH = "preferred_username";
        # GF_AUTH_GENERIC_OAUTH_GROUPS_ATTRIBUTE_PATH = "groups";
        # GF_AUTH_GENERIC_OAUTH_NAME_ATTRIBUTE_PATH = "name";
        # GF_AUTH_GENERIC_OAUTH_USE_PKCE = "true";
        # GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH = "";
      };
      volumes = [
        "grafana_data:/var/lib/grafana"
      ];
      ports = [
        "3000:3000"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.grafana.rule" = "Host(`grafana.trev.zip`)";
        "traefik.http.routers.grafana.entryPoints" = "https";
        "traefik.http.routers.grafana.tls" = "true";
        "traefik.http.routers.grafana.tls.certresolver" = "letsencrypt";
      };
    };
  };
}
