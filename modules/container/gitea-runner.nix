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
                labels = [
                  "ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest"
                  "ubuntu-22.04:docker://docker.gitea.com/runner-images:ubuntu-22.04"
                  "ubuntu-20.04:docker://docker.gitea.com/runner-images:ubuntu-20.04"
                  "node-24:docker://node:24-bookworm"
                ];
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
            image = "docker.io/gitea/act_runner:nightly@sha256:73394e4f5702115c64de57c623db4386aefafe1277fd005b292a68f9ee2f381a";
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
