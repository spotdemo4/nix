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
      image = "docker.io/dockurr/tor:0.4.9.8@sha256:b4cb4770d4c08c73881255b0aea868bffce1bc0d2ef0b859d226422d8c6626cf";
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
