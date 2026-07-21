{ config, self, ... }:
{
  imports = [
    (self + /modules/container/bazarr)
    (self + /modules/container/discord-embedder)
    (self + /modules/container/gluetun)
    (self + /modules/container/plex)
    (self + /modules/container/portainer-agent)
    (self + /modules/container/prowlarr)
    (self + /modules/container/qbittorrent)
    (self + /modules/container/qbittorrent-port-glue)
    (self + /modules/container/radarr)
    (self + /modules/container/sabnzbd)
    (self + /modules/container/seerr)
    (self + /modules/container/sonarr)
    (self + /modules/container/tautulli)
    (self + /modules/container/traefik-kop)
    (self + /modules/container/unpackerr)
  ];

  trev.containers = {
    bazarr.enable = true;
    discord-embedder.enable = true;
    plex.enable = true;
    portainer-agent.enable = true;
    prowlarr.enable = true;
    qbittorrent.enable = true;
    qbittorrent-port-glue.enable = true;
    radarr.enable = true;
    sabnzbd.enable = true;
    seerr.enable = true;
    sonarr.enable = true;
    tautulli.enable = true;
    unpackerr.enable = true;

    gluetun = {
      enable = true;
      instances.qbittorrent = {
        enable = true;
        secret = config.virtualisation.quadlet.secrets.protonvpn-qbittorrent;
        ports = [ "8185" ];
        environments = {
          VPN_SERVICE_PROVIDER = "protonvpn";
          VPN_TYPE = "wireguard";
          SERVER_CITIES = "Chicago,Toronto";
          PORT_FORWARD_ONLY = "on";
          VPN_PORT_FORWARDING = "on";
        };
        networks = [
          config.virtualisation.quadlet.networks.sonarr.ref
          config.virtualisation.quadlet.networks.radarr.ref
        ];
      };
    };

    traefik-kop = {
      enable = true;
      ip = "10.10.10.107";
    };
  };
}
