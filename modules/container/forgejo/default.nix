{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.forgejo;
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.forgejo = {
    enable = mkEnableOption "Forgejo container";
    image = containerOptions.mkImageOption "codeberg.org/forgejo/forgejo:15.0.5@sha256:eda2e378442d2f18cfa563994f8ad66e71f04ac9c3bb4259cc57bdd641890f5c";

    domain = mkOption {
      type = types.str;
      default = "trev.zip";
      description = "Domain routed to Forgejo.";
    };

    localtimePath = mkOption {
      type = types.str;
      default = "/etc/localtime";
      description = "Host localtime file mounted into Forgejo.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Forgejo HTTP port to publish.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.forgejo.containerConfig = {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${volumes.forgejo.ref}:/data"
          "${cfg.localtimePath}:/etc/localtime:ro"
        ];
        publishPorts = [
          (toString cfg.port)
        ];
        networks = [
          networks.forgejo.ref
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.forgejo = {
              rule = "Host(`${cfg.domain}`)";
              middlewares = "secure@file";
            };
          };
        };
      };

      volumes.forgejo = { };
      networks.forgejo = { };
    };
  };
}
