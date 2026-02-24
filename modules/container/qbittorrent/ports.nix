{
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers volumes;
  inherit (config) secrets gluetun;
in
{
  virtualisation.quadlet = {
    containers.qbittorrent-port-glue = {
      containerConfig = {
        image = "ghcr.io/spotdemo4/qbittorrent-port-glue:0.1.1@sha256:28587cf6c7b28ed3e8464a36f476ea11881e8a0a204cdaae852f0f438f8c7cc1";
        pull = "missing";
        environments = {
          QBITTORRENT_HOST = "http://localhost";
          QBITTORRENT_PORT = "8185";
          QBITTORRENT_USER = "trev";
          PORT_FILE = "/tmp/gluetun/forwarded_port";
        };
        secrets = [
          "${secrets."password".env},target=QBITTORRENT_PASS"
        ];
        volumes = [
          "${volumes."gluetun-qbittorrent".ref}:/tmp/gluetun"
        ];
        networks = [
          "container:${gluetun."qbittorrent".ref}"
        ];
      };

      unitConfig = {
        BindsTo = containers."qbittorrent".ref;
        After = containers."qbittorrent".ref;
        ReloadPropagatedFrom = containers."qbittorrent".ref;
      };
    };
  };
}
