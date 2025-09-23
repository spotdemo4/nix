{
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) containers volumes networks;
  inherit (config) mysql;
  toLabel = import (self + /modules/util/label);
in {
  imports = [./mysql.nix];

  secrets = {
    "mysql-roundcube".file = self + /secrets/mysql-roundcube.age;
  };

  mysql."roundcube" = {
    database = "mail";
    username = "roundcube";
    password = config.secrets."mysql-roundcube";
    networks = [
      networks."roundcube".ref
    ];
  };

  virtualisation.quadlet = {
    containers = {
      roundcube = {
        containerConfig = {
          image = "docker.io/roundcube/roundcubemail:1.6.11-fpm-alpine@sha256:6f1a4ff3594cb1b81fe49e4dac2bd49a74216b686cb9db48a19c0ced2e8517c5";
          pull = "missing";
          environments = {
            ROUNDCUBEMAIL_DEFAULT_HOST = "stalwart";
            ROUNDCUBEMAIL_DEFAULT_PORT = "143";
            ROUNDCUBEMAIL_SMTP_SERVER = "stalwart";
            ROUNDCUBEMAIL_SMTP_PORT = "25";

            ROUNDCUBEMAIL_DB_TYPE = "mysql";
            ROUNDCUBEMAIL_DB_HOST = mysql."roundcube".ref;
            ROUNDCUBEMAIL_DB_PORT = "3306";
            ROUNDCUBEMAIL_DB_NAME = mysql."roundcube".database;
            ROUNDCUBEMAIL_DB_USER = mysql."roundcube".username;
          };
          secrets = [
            "${mysql."roundcube".password.env},target=ROUNDCUBEMAIL_DB_PASSWORD"
          ];
          volumes = [
            "${volumes."roundcube".ref}:/var/www/html"
          ];
          publishPorts = [
            "80"
          ];
          networks = [
            networks."stalwart".ref
            networks."roundcube".ref
          ];
          labels = toLabel {
            attrs = {
              traefik = {
                enable = true;
                http.routers.grafana = {
                  rule = "HostRegexp(`roundcube.trev.(zip|kiwi)`)";
                  middlewares = "auth-github@docker";
                };
              };
            };
          };
        };

        unitConfig = {
          After = containers."mysql-roundcube".ref;
          BindsTo = containers."mysql-roundcube".ref;
          ReloadPropagatedFrom = containers."mysql-roundcube".ref;
        };
      };
    };

    volumes = {
      roundcube = {};
    };

    networks = {
      roundcube = {};
    };
  };
}
