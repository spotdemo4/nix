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
      image = "docker.io/dockurr/tor:0.4.9.8@sha256:36590e184e88be6449b8df4e5cccd113480a579185da15d72d1fe03ec68929ab";
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
