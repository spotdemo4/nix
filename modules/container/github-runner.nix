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
              image = "ghcr.io/myoung34/docker-github-actions-runner:2.327.1-ubuntu-noble@sha256:b52abfdd17f3165f797deacc7d9e8bf9049c8c0c7bae9dfa2e88ab0e561a32c9";
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
