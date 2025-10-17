{
  self,
  lib,
  config,
  ...
}: {
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
      containers = lib.listToAttrs (map (repo:
        lib.nameValuePair "github-runner-${builtins.replaceStrings ["/" "."] ["-" ""] repo}" {
          containerConfig = {
            image = "ghcr.io/myoung34/docker-github-actions-runner:2.329.0-ubuntu-noble@sha256:d1b2a28ffbcb6340d2cf6463021a84920e67a64c69ea4b050b236ec1706192a7";
            pull = "missing";
            environments = {
              REPO_URL = "https://github.com/${repo}";
              RUNNER_NAME = "${builtins.replaceStrings ["/"] ["-"] repo}";
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
              "github-runner-${builtins.replaceStrings ["/" "."] ["-" ""] repo}:/runner/data"
            ];
          };

          unitConfig = {
            After = "podman.socket";
            BindsTo = "podman.socket";
            ReloadPropagatedFrom = "podman.socket";
          };
        })
      config.github-runner.repos);

      volumes = lib.listToAttrs (map (repo:
        lib.nameValuePair "github-runner-${builtins.replaceStrings ["/" "."] ["-" ""] repo}" {})
      config.github-runner.repos);
    };
  };
}
