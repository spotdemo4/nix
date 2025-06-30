{
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
    virtualisation.quadlet.containers = lib.mapAttrs' (name: value:
      lib.nameValuePair "runner-${name}" {
        containerConfig = {
          image = "docker.io/gitea/act_runner:nightly";
          pull = "newer";
          autoUpdate = "registry";
          environments = {
            GITEA_INSTANCE_URL = value.url;
          };
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
          ];
          environmentFiles = [
            value.tokenFile
          ];
        };

        unitConfig = {
          After = "podman.socket";
          BindsTo = "podman.socket";
          ReloadPropagatedFrom = "podman.socket";
        };
      })
    config.gitea-runner.instances;
  };
}
