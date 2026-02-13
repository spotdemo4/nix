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
      image = "docker.io/dockurr/tor:0.4.9.5@sha256:17b7a3c4d264f7776d6a3f986a1b4f7dde45c3f8ed43e598c69887be3ac9fb37";
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
        "9091:9091" # metrics
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
