{
  self,
  pkgs,
  config,
  ...
}: let
  configFile = (pkgs.formats.yaml {}).generate "configuration.yml" {
    server.address = "tcp://:9091";
    log.level = "debug";

    authentication_backend = {
      password_change.disable = true;
      password_reset.disable = true;
      file.path = "/config/users.yml";
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
  age.secrets."authelia".file = self + /secrets/authelia.age;

  virtualisation.oci-containers.containers = {
    authelia = {
      image = "authelia/authelia:latest";
      pull = "newer";
      volumes = [
        "authelia_data:/data"
        "${configFile}:/config/configuration.yml"
        "${usersFile}:/config/users.yml"
        "${config.age.secrets."authelia".path}:/secret/session"
      ];
      networks = [
        "traefik"
      ];
      environment = {
        TZ = "America/Detroit";
        AUTHELIA_SESSION_SECRET_FILE = "/secret/session";
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
