{
  self,
  pkgs,
  config,
  ...
}: {
  age.secrets."grafana".file = self + /secrets/grafana.age;

  virtualisation.quadlet = let
    utils = import ./utils.nix;
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    containers.grafana.containerConfig = {
      image = "docker.io/grafana/grafana-enterprise:latest";
      pull = "newer";
      autoUpdate = "registry";
      user = "root";
      environments = {
        GF_SERVER_ROOT_URL = "https://grafana.trev.zip";
        GF_AUTH_GENERIC_OAUTH_ENABLED = "true";
        GF_AUTH_GENERIC_OAUTH_NAME = "Authelia";
        GF_AUTH_GENERIC_OAUTH_ICON = "signin";
        GF_AUTH_GENERIC_OAUTH_CLIENT_ID = "pmdxrEV_TTNxQe3FwL9yfybbuFNLdbUjfBpOU5kSczmEfMkQPlAvpormWW~xIQNsf17JeJ5x";
        GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = "$__file{/etc/secrets/client}";
        GF_AUTH_GENERIC_OAUTH_SCOPES = "openid profile email groups";
        GF_AUTH_GENERIC_OAUTH_EMPTY_SCOPES = "false";
        GF_AUTH_GENERIC_OAUTH_AUTH_URL = "https://auth.trev.zip/api/oidc/authorization";
        GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "https://auth.trev.zip/api/oidc/token";
        GF_AUTH_GENERIC_OAUTH_API_URL = "https://auth.trev.zip/api/oidc/userinfo";
        GF_AUTH_GENERIC_OAUTH_LOGIN_ATTRIBUTE_PATH = "preferred_username";
        GF_AUTH_GENERIC_OAUTH_GROUPS_ATTRIBUTE_PATH = "groups";
        GF_AUTH_GENERIC_OAUTH_NAME_ATTRIBUTE_PATH = "name";
        GF_AUTH_GENERIC_OAUTH_USE_PKCE = "true";
        GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH = "'Admin'";
        GF_AUTH_GENERIC_OAUTH_SKIP_ORG_ROLE_SYNC = "false";
      };
      volumes = [
        "${volumes.grafana_data.ref}:/var/lib/grafana"
        "${config.age.secrets."grafana".path}:/etc/secrets/client"
      ];
      publishPorts = [
        "3000:3000"
      ];
      networks = [
        networks.victoria-metrics.ref
      ];
      labels = utils.toEnvStrings [] {
        traefik = {
          enable = true;
          http.routers.grafana = {
            rule = "Host(`grafana.trev.zip`)";
            entryPoints = "https";
            tls.certresolver = "letsencrypt";
          };
        };
      };
    };

    volumes = {
      grafana_data = {};
    };
  };
}
