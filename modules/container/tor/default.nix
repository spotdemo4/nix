{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.tor.containerConfig = {
      image = "docker.io/dockurr/tor:0.4.8.21@sha256:506e63aca4a9519f40196c2b4a079a8f2066b169ec22e3a1a00f9ac0eadb2ead";
      pull = "missing";
      volumes = [
        "${volumes."tor".ref}:/var/lib/tor"
        "${./torrc}:/var/lib/tor/torrc"
      ];
      networks = [
        networks."traefik".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          tcp = {
            services.tor.loadbalancer.server.port = 9090;
            routers.tor = {
              rule = "HostSNI(`*`)";
              entryPoints = "tor";
              service = "tor";
            };
          };
        };
      };
    };

    volumes = {
      tor = { };
    };
  };
}
