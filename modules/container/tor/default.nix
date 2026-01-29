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
      image = "docker.io/dockurr/tor:0.4.8.22@sha256:fa48248e790ca95a5b2cd30712ce4c90c3fd6e5d9bb5b21f134ab5e94ff6c841";
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
