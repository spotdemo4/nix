{
  pkgs,
  config,
  lib,
  ...
}: {
  options.gitea-runner = {
    enable = lib.mkEnableOption "enable gitea runner";

    instances = lib.mkOption {
      type = lib.types.attrs;
      example = {
        instance1 = {
          tokenFile = "/run/secrets/token1";
          url = "https://gitea.com";
        };
      };
    };
  };

  config = lib.mkIf config.gitea-runner.enable {
    virtualisation.quadlet = let
      inherit (config.virtualisation.quadlet) networks volumes;
    in {
      containers = lib.mapAttrs' (name: value:
        lib.nameValuePair "runner-${name}" {
          containerConfig = let
            configFile = (pkgs.formats.yaml {}).generate "config.yaml" {
              runner = {
                capacity = 2;
              };
              cache = {
                enabled = true;
                dir = "/cache";
                host = "runner-${name}";
                port = 8088;
              };
              container = {
                network = "runner-${name}";
              };
            };
          in {
            image = "docker.io/gitea/act_runner:0.2.12@sha256:62a561c82dd67ec77ea600db7eac78ac5fed8e2244950fbf1829c54da12e8e54";
            pull = "missing";
            environments = {
              CONFIG_FILE = "/config.yaml";
              GITEA_INSTANCE_URL = value.url;
            };
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock"
              "${configFile}:/config.yaml"
              "${volumes."runner-${name}".ref}:/cache"
            ];
            environmentFiles = [
              value.tokenFile
            ];
            networks = [
              networks."runner-${name}".ref
            ];
          };

          unitConfig = {
            After = "podman.socket";
            BindsTo = "podman.socket";
            ReloadPropagatedFrom = "podman.socket";
          };
        })
      config.gitea-runner.instances;

      networks = lib.mapAttrs' (name: value: lib.nameValuePair "runner-${name}" {});
      volumes = lib.mapAttrs' (name: value: lib.nameValuePair "runner-${name}" {});
    };
  };
}
