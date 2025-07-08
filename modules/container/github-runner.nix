{
  pkgs,
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

  config = let
    mkSecret = (import ./utils/mkSecret.nix {inherit pkgs config;}).mkSecret;

    githubSecret = mkSecret "github-runner" config.age.secrets."github-runner".path;
  in
    lib.mkIf config.github-runner.enable {
      age.secrets."${githubSecret.ref}".file = self + /secrets/github-runner.age;
      system.activationScripts = {
        "${githubSecret.ref}" = githubSecret.script;
      };

      virtualisation.quadlet = {
        containers = lib.listToAttrs (map (repo:
          lib.nameValuePair "github-runner-${builtins.replaceStrings ["/" "."] ["-" ""] repo}" {
            containerConfig = {
              image = "ghcr.io/myoung34/docker-github-actions-runner:2.326.0-ubuntu-noble@sha256:92588cb4ba628304dab2b9fc917c646da246cc7aa94dc2c6b8ea0e0be0937e84";
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
                "${githubSecret.ref},type=env,target=ACCESS_TOKEN"
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
