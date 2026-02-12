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
        image = "ghcr.io/spotdemo4/qbittorrent-port-glue:0.0.2@sha256:ac740ed0df44d74e4d807d4f278794fff53bd3bd19bc171e6e1a1e8c2f98eaf5";
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
