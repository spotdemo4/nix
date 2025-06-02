{
  self,
  pkgs,
  config,
  ...
}: let
  configFile = (pkgs.formats.yaml {}).generate "configuration.yml" {
    theme = "dark";
    server.address = "tcp://:9091";
    log.level = "debug";

    # First factor
    authentication_backend = {
      password_change.disable = true;
      password_reset.disable = true;
      file.path = "/config/users.yml";
    };

    # Second factor
    totp.disable = true;
    webauthn.disable = true;

    # Will get this working once email is fixed
    # webauthn = {
    #   disable = true;
    #   enable_passkey_login = true;
    #   display_name = "Authelia";
    # };

    identity_validation = {
      elevated_session = {
        require_second_factor = false;
        skip_second_factor = true;
      };
    };

    identity_providers.oidc = {
      clients = [
        {
          client_name = "Portainer";
          client_id = "UDdG1zZOSI_Dc2rgwT4CZHUKH2PZ7JtIbz9LV6qlsmHT5RLutOOMsSz6EreDu7W4sVj6sOgp";
          client_secret = "$pbkdf2-sha512$310000$b8BYivPoYH.pDy2MSv2yIQ$crkn3J9RY5.zFJ.ie28S403vzxqIcVk5AL6rV59tbtJ4HVz7.6R5yOCbgcRKcaowUD3/SpiOxatLrc1fnKcmeg";
          public = false;
          authorization_policy = "one_factor";
          redirect_uris = [
            "https://port.trev.zip"
          ];
          scopes = [
            "openid"
            "profile"
            "groups"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          client_name = "Grafana";
          client_id = "pmdxrEV_TTNxQe3FwL9yfybbuFNLdbUjfBpOU5kSczmEfMkQPlAvpormWW~xIQNsf17JeJ5x";
          client_secret = "$pbkdf2-sha512$310000$450SHQMQDNEtUf0Itt625g$oIkAoLa0vpFNNW8u1iVISuMwDzbvGaQuj0mrx7VkxUfZb.RT6z9DzYZ3ChZmk9GDrOAM7fnFooKXmn7IyKFjqw";
          public = false;
          authorization_policy = "one_factor";
          redirect_uris = [
            "https://grafana.trev.zip/login/generic_oauth"
          ];
          scopes = [
            "openid"
            "profile"
            "groups"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          client_name = "OpenWebUI";
          client_id = "9mW~ikpyry2l25iGOQSmqcytairhq4kxxwbbiJErQjmnoLkm0qsy5cduBJGQ-F_kpPpLJVfe";
          client_secret = "$pbkdf2-sha512$310000$9.iktk1kvIEBscaAJYwfXg$eC4hZG7QdWr5GyMpwhJsysyigcKu.ZWb1Uw7YEO4bHnjTaw45zYZ1etQINw2z/3auXw5.GAZjEfdnrZZ7JihXg";
          public = false;
          authorization_policy = "one_factor";
          redirect_uris = [
            "https://chat.trev.zip/oauth/oidc/callback"
          ];
          scopes = [
            "openid"
            "profile"
            "groups"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
      ];
    };

    access_control = {
      default_policy = "deny";
      rules = [
        {
          domain = "*.trev.zip";
          policy = "one_factor";
        }
      ];
    };

    session = {
      cookies = [
        {
          name = "authelia_session";
          domain = "trev.zip";
          authelia_url = "https://auth.trev.zip";
          expiration = "1 hour";
          inactivity = "5 minutes";
        }
      ];
    };

    regulation = {
      max_retries = 3;
      find_time = "2 minutes";
      ban_time = "5 minutes";
    };

    storage = {
      encryption_key = "mOuTF00uet6bTHfXm9kjD";
      local.path = "/data/db.sqlite3";
    };

    notifier = {
      disable_startup_check = true;
      filesystem.filename = "/data/notification.txt";
    };
  };

  usersFile = (pkgs.formats.yaml {}).generate "users.yml" {
    users = {
      trev = {
        disabled = false;
        displayname = "Trev";
        password = "$argon2id$v=19$m=65536,t=3,p=4$fv/ncqO40/0Hbo8ehy+IVQ$IhzvTfxfYKrd+ToJvZ+CezHaimlfyxFHNJccfdIqFsg";
        email = "me@trev.xyz";
        picture = "https://avatars.githubusercontent.com/spotdemo4";
        groups = [
          "admin"
          "user"
        ];
      };
    };
  };
in {
  # Get secrets
  age.secrets."authelia-session".file = self + /secrets/authelia-session.age;
  age.secrets."authelia-hmac".file = self + /secrets/authelia-hmac.age;
  age.secrets."authelia-private-key".file = self + /secrets/authelia-private-key.age;

  virtualisation.quadlet = let
    toLabel = (import ./utils/toLabel.nix).toLabel;
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    containers.authelia.containerConfig = {
      image = "docker.io/authelia/authelia:latest";
      pull = "newer";
      autoUpdate = "registry";
      environments = {
        TZ = "America/Detroit";
        AUTHELIA_SESSION_SECRET_FILE = "/secret/session";
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = "/secret/hmac";
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY_FILE = "/secret/private-key";
      };
      volumes = [
        "${volumes.authelia_data.ref}:/data"
        "${configFile}:/config/configuration.yml"
        "${usersFile}:/config/users.yml"
        "${config.age.secrets."authelia-session".path}:/secret/session"
        "${config.age.secrets."authelia-hmac".path}:/secret/hmac"
        "${config.age.secrets."authelia-private-key".path}:/secret/private-key"
      ];
      networks = [
        networks.traefik.ref
      ];
      labels = toLabel [] {
        traefik = {
          enable = true;
          http = {
            routers.authelia = {
              rule = "Host(`auth.trev.zip`)";
              entryPoints = "https";
              tls.certresolver = "letsencrypt";
            };
            middlewares.authelia.forwardAuth = {
              address = "http://authelia:9091/api/authz/forward-auth";
              trustForwardHeader = true;
              authResponseHeaders = "Remote-User,Remote-Groups,Remote-Email,Remote-Name";
            };
          };
        };
      };
    };

    volumes = {
      authelia_data = {};
    };
  };
}
