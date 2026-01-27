{
  self,
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers volumes networks;
  inherit (config) mysql;
  toLabel = import (self + /modules/util/label);
in
{
  imports = [ ./mysql.nix ];

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
          image = "docker.io/roundcube/roundcubemail:1.6.12-apache@sha256:57b76bf838fe99a85e88d8d87207de7b9294a7eeba4157c10fda69ee32f4f4e4";
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
                http.routers.roundcube = {
                  rule = "HostRegexp(`roundcube.trev.(zip|kiwi)`)";
                  middlewares = "secure-admin@file";
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
      roundcube = { };
    };

    networks = {
      roundcube = { };
    };
  };
}
