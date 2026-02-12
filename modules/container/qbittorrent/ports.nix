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
        image = "ghcr.io/spotdemo4/qbittorrent-port-glue:0.1.0@sha256:45c274cee588a11a45bba89f99a98c73ddba5a53711fbc5643f11ac826d4dda4";
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
