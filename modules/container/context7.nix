{...}: let
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet.containers.context7.containerConfig = {
    image = "docker.io/mcp/context7:latest";
    pull = "newer";
    autoUpdate = "registry";
    publishPorts = [
      "8080"
    ];
    labels = toLabel [] {
      traefik = {
        enable = true;
        http = {
          routers.context7 = {
            rule = "Host(`context7.trev.zip`)";
            entryPoints = "https";
            tls.certresolver = "letsencrypt";
          };
        };
      };
    };
  };
}
