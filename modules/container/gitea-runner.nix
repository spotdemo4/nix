{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
in {
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
    virtualisation.quadlet = {
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
            image = "docker.io/gitea/act_runner:nightly@sha256:aa1f4931aa0e840e4fd50f8dc52838a8f1fc0fd2e03bab4d0666f13a834abece";
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

      networks = lib.mapAttrs' (name: value: lib.nameValuePair "runner-${name}" {}) config.gitea-runner.instances;
      volumes = lib.mapAttrs' (name: value: lib.nameValuePair "runner-${name}" {}) config.gitea-runner.instances;
    };
  };
}
