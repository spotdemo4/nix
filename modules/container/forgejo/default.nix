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
    image = containerOptions.mkImageOption "codeberg.org/forgejo/forgejo:15.0.4@sha256:9e14382433760127c87cb78c4dbc44b45abbb0c09c8479812c8e99b3dc893429";

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
