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
    containers.qbittorrent-ports = {
      containerConfig = {
        image = "docker.io/snoringdragon/gluetun-qbittorrent-port-manager:1.3@sha256:679b7a92c494f93b78ad37ef24f3a261e73d0a1a52505ad4f1e39580eedfa14f";
        pull = "missing";
        environments = {
          QBITTORRENT_SERVER = "localhost";
          QBITTORRENT_PORT = "8185";
          QBITTORRENT_USER = "trev";
          PORT_FORWARDED = "/tmp/gluetun/forwarded_port";
          HTTP_S = "http";
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
        After = containers."qbittorrent".ref;
        BindsTo = containers."qbittorrent".ref;
        ReloadPropagatedFrom = containers."qbittorrent".ref;
      };
    };
  };
}
