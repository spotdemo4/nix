{
  config,
  self,
  ...
}:
{
  imports = [
    (self + /modules/container/cobalt)
    (self + /modules/container/cobalt-web)
    (self + /modules/container/cobalt-youtube)
    (self + /modules/container/crowdsec)
    (self + /modules/container/discord-openrouter)
    (self + /modules/container/gluetun)
    (self + /modules/container/portainer-agent)
    (self + /modules/container/postgresql)
    (self + /modules/container/shlink)
    (self + /modules/container/shlink-web)
    (self + /modules/container/traefik-kop)
  ];

  virtualisation.quadlet = {
    secrets = {
      protonvpn-cobalt.file = toString (self + /secrets/protonvpn-cobalt.age);
      shlink-postgresql.file = toString (self + /secrets/shlink-postgresql.age);
    };
  };

  trev.containers = {
    cobalt.enable = true;
    cobalt-web.enable = true;
    crowdsec.enable = true;
    discord-openrouter.enable = true;
    portainer-agent.enable = true;
    shlink.enable = true;
    shlink-web.enable = true;

    gluetun = {
      enable = true;
      instances.cobalt = {
        enable = true;
        secret = config.virtualisation.quadlet.secrets.protonvpn-cobalt;
        ports = [ "9000" ];
        environments = {
          VPN_SERVICE_PROVIDER = "protonvpn";
          VPN_TYPE = "wireguard";
          SERVER_CITIES = "Chicago,Toronto";
          STREAM_ONLY = "on";
        };
      };
    };

    postgresql = {
      enable = true;
      instances.shlink = {
        enable = true;
        database = "shlink";
        username = "shlink";
        networks = [ config.virtualisation.quadlet.networks.shlink.ref ];
        passwordSecret = config.virtualisation.quadlet.secrets.shlink-postgresql;
      };
    };

    traefik-kop = {
      enable = true;
      ip = "10.10.10.114";
    };
  };
}
