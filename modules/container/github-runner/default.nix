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
              image = "ghcr.io/myoung34/docker-github-actions-runner:2.335.1-ubuntu-noble@sha256:e2e1ff7077ffa67986a5db7dd61b473cc3b0f661a6db8bfee41cb59eb9aab4d1";
              pull = "missing";
              environments = {
                REPO_URL = "https://github.com/${repo}";
                RUNNER_NAME = "builder";
                LABELS = "builder";
                CONFIGURED_ACTIONS_RUNNER_FILES_DIR = "/runner/data";
                DISABLE_AUTOMATIC_DEREGISTRATION = "true";
                RUNNER_SCOPE = "repo";
                RUN_AS_ROOT = "false";
                USER = "runner";
                DISABLE_AUTO_UPDATE = "true";
                NO_DEFAULT_LABELS = "true";
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
