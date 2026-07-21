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
  inherit (import ../../../lib/container-options.nix { inherit lib; })
    mkContainer
    mkImageOption
    ;
  cfg = config.trev.containers.forgejo;
  inherit (config.virtualisation.quadlet) networks volumes;
in
{
  options.trev.containers.forgejo = {
    enable = mkEnableOption "Forgejo container";
    image = mkImageOption "codeberg.org/forgejo/forgejo:15.0.5@sha256:eda2e378442d2f18cfa563994f8ad66e71f04ac9c3bb4259cc57bdd641890f5c";

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

    lfsSecretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/forgejo-lfs.age;
      description = "Age file containing the LFS JWT secret.";
    };
    jwtSecretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/forgejo-jwt.age;
      description = "Age file containing the JWT secret.";
    };
    tokenSecretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/forgejo-token.age;
      description = "Age file containing the internal token.";
    };
  };

  config = mkIf cfg.enable {
    secrets = {
      forgejo-lfs.file = cfg.lfsSecretFile;
      forgejo-jwt.file = cfg.jwtSecretFile;
      forgejo-token.file = cfg.tokenSecretFile;
    };

    virtualisation.quadlet = {
      containers.forgejo.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${volumes.forgejo.ref}:/data"
          "${./app.ini}:/data/gitea/conf/app.ini"
          "${cfg.localtimePath}:/etc/localtime:ro"
        ];
        secrets = [
          "${config.secrets.forgejo-lfs.mount},target=/secrets/forgejo-lfs,mode=0400"
          "${config.secrets.forgejo-jwt.mount},target=/secrets/forgejo-jwt,mode=0400"
          "${config.secrets.forgejo-token.mount},target=/secrets/forgejo-token,mode=0400"
        ];
        publishPorts = [
          (toString cfg.port)
        ];
        networks = [
          networks.forgejo.ref
        ];
        labels = {
          traefik = {
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
