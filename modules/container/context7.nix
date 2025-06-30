{...}: let
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet.containers.context7.containerConfig = {
    image = "docker.io/mcp/context7:latest@sha256:1deaf09150eb2b84f845b132ccd61437cc9308f9d9d7b16aafd4c44a07625ca4";
    pull = "missing";
    publishPorts = [
      "8080"
    ];
    labels = toLabel [] {
      traefik = {
        enable = true;
        http.routers.context7 = {
          rule = "HostRegexp(`context7.trev.(zip|kiwi)`)";
        };
      };
    };
  };
}
