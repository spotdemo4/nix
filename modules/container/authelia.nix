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

    authentication_backend = {
      password_change.disable = true;
      password_reset.disable = true;
      file.path = "/config/users.yml";
    };

    identity_providers.oidc = {
      jwks = [
        {
          key = "{{ secret \"/secret/private-key\" | mindent 10 \"|\" | msquote }}";
        }
      ];

      clients = [
        {
          client_id = "UDdG1zZOSI_Dc2rgwT4CZHUKH2PZ7JtIbz9LV6qlsmHT5RLutOOMsSz6EreDu7W4sVj6sOgp";
          client_name = "Portainer";
          client_secret = "$pbkdf2-sha512$310000$b8BYivPoYH.pDy2MSv2yIQ$crkn3J9RY5.zFJ.ie28S403vzxqIcVk5AL6rV59tbtJ4HVz7.6R5yOCbgcRKcaowUD3/SpiOxatLrc1fnKcmeg";
          public = false;
          authorization_policy = "one_factor";
          redirect_uris = [
            "https://portainer.trev.zip"
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
        groups = [
          "admins"
          "dev"
        ];
      };
    };
  };
in {
  # Create volume for authelia
  system.activationScripts.mkAuthelia = ''
    ${pkgs.podman}/bin/podman volume inspect authelia_data || ${pkgs.podman}/bin/podman volume create authelia_data
  '';

  # Get session secret
  age.secrets."authelia-session".file = self + /secrets/authelia-session.age;
  age.secrets."authelia-hmac".file = self + /secrets/authelia-hmac.age;
  age.secrets."authelia-private-key".file = self + /secrets/authelia-private-key.age;

  virtualisation.oci-containers.containers = {
    authelia = {
      image = "authelia/authelia:latest";
      pull = "newer";
      volumes = [
        "authelia_data:/data"
        "${configFile}:/config/configuration.yml"
        "${usersFile}:/config/users.yml"
        "${config.age.secrets."authelia-session".path}:/secret/session"
        "${config.age.secrets."authelia-hmac".path}:/secret/hmac"
        "${config.age.secrets."authelia-private-key".path}:/secret/private-key"
      ];
      networks = [
        "traefik"
      ];
      environment = {
        TZ = "America/Detroit";
        AUTHELIA_SESSION_SECRET_FILE = "/secret/session";
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = "/secret/hmac";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.authelia.rule" = "Host(`auth.trev.zip`)";
        "traefik.http.routers.authelia.entryPoints" = "https";
        "traefik.http.routers.authelia.tls" = "true";
        "traefik.http.routers.authelia.tls.certresolver" = "letsencrypt";
        "traefik.http.middlewares.authelia.forwardAuth.address" = "http://authelia:9091/api/authz/forward-auth";
        "traefik.http.middlewares.authelia.forwardAuth.trustForwardHeader" = "true";
        "traefik.http.middlewares.authelia.forwardAuth.authResponseHeaders" = "Remote-User,Remote-Groups,Remote-Email,Remote-Name";
      };
    };
  };
}
