{...}: let
  utils = import ./utils.nix;
in {
  virtualisation.quadlet.containers.context7.containerConfig = {
    image = "docker.io/mcp/context7:latest";
    pull = "newer";
    autoUpdate = "registry";
    publishPorts = [
      "8080:8080"
    ];
    labels = utils.toEnvStrings [] {
      traefik = {
        enable = true;
        http = {
          routers.context7 = {
            rule = "Host(`context7.trev.zip`)";
            entryPoints = "https";
            tls.certresolver = "letsencrypt";
            middlewares = "authelia@docker";
          };
          services.context7.loadbalancer.server = {
            scheme = "http";
            port = 8080;
          };
        };
      };
    };
  };
}
