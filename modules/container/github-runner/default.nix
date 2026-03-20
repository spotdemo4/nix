{
  self,
  lib,
  config,
  ...
}:
{
  options.github-runner = {
    enable = lib.mkEnableOption "enable github runner";

    repos = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [
        "spotdemo4/nix"
      ];
      description = ''
        List of github repos
      '';
    };
  };

  config = lib.mkIf config.github-runner.enable {
    secrets."github-runner".file = self + /secrets/github-runner.age;

    virtualisation.quadlet = {
      containers = lib.listToAttrs (
        map (
          repo:
          lib.nameValuePair "github-runner-${builtins.replaceStrings [ "/" "." ] [ "-" "" ] repo}" {
            containerConfig = {
              image = "ghcr.io/myoung34/docker-github-actions-runner:2.333.0-ubuntu-noble@sha256:d7eaf5f429719cc1c6ec6ceee06a81cf74716899058dd646debfeb61d35b5174";
              pull = "missing";
              environments = {
                REPO_URL = "https://github.com/${repo}";
                RUNNER_NAME = "${builtins.replaceStrings [ "/" ] [ "-" ] repo}";
                RUNNER_SCOPE = "repo";
                LABELS = "linux,x64";
                CONFIGURED_ACTIONS_RUNNER_FILES_DIR = "/runner/data";
                DISABLE_AUTOMATIC_DEREGISTRATION = "true";
                RUN_AS_ROOT = "false";
                USER = "runner";
              };
              secrets = [
                "${config.secrets."github-runner".env},target=ACCESS_TOKEN"
              ];
              volumes = [
                "/run/podman/podman.sock:/var/run/docker.sock"
                "github-runner-${builtins.replaceStrings [ "/" "." ] [ "-" "" ] repo}:/runner/data"
              ];
            };

            unitConfig = {
              After = "podman.socket";
              BindsTo = "podman.socket";
              ReloadPropagatedFrom = "podman.socket";
            };
          }
        ) config.github-runner.repos
      );

      volumes = lib.listToAttrs (
        map (
          repo: lib.nameValuePair "github-runner-${builtins.replaceStrings [ "/" "." ] [ "-" "" ] repo}" { }
        ) config.github-runner.repos
      );
    };
  };
}
