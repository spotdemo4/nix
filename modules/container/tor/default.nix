{
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
in
{
  virtualisation.quadlet = {
    containers.tor.containerConfig = {
      image = "docker.io/dockurr/tor:0.4.9.10@sha256:7c8aff7c37d48ecf49db40f1508b157eedaf992d6ff49b0ec7b19b1bbf17759a";
      pull = "missing";
      volumes = [
        "${volumes."tor".ref}:/var/lib/tor"
        "${./torrc}:/etc/tor/torrc"
      ];
      networks = [
        networks."tor".ref
      ];
      publishPorts = [
        "9090:9090"
        "10.10.10.105:9091:9091" # metrics
      ];
    };

    volumes = {
      tor = { };
    };

    networks = {
      tor = { };
    };
  };
}
