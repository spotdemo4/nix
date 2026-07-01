{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes;
  inherit (config) secrets;
  toLabel = import (self + /modules/util/label);
in
{
  secrets."rsyncd".file = self + /secrets/rsyncd.age;

  virtualisation.quadlet = {
    containers.rsyncd.containerConfig = {
      image = "docker.io/vimagick/rsyncd:latest@sha256:fb98a50388b111940d0e4cae0b9fd5f1606b970caa713dfb1ec1c680b8290638";
      pull = "missing";
      secrets = [
        "${secrets."rsyncd".mount},target=/etc/rsyncd.secrets,mode=0400"
      ];
      volumes = [
        "${./rsyncd.conf}:/etc/rsyncd.conf"
        "${volumes.codex.ref}:/codex"
      ];
      publishPorts = [
        "873:873"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          tcp = {
            routers.rsyncd = {
              rule = "HostSNI(`*`)";
              entryPoints = "rsyncd";
              service = "rsyncd";
            };
            services.rsyncd.loadbalancer.server.port = 873;
          };
        };
      };
    };

    volumes.codex = { };
  };
}
