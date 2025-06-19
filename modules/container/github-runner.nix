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

      virtualisation.quadlet.containers = lib.listToAttrs (map (repo:
        lib.nameValuePair "github-runner-${lib.strings.replaceChars ["/" "."] ["-" ""] repo}" {
          containerConfig = {
            image = "ghcr.io/myoung34/docker-github-actions-runner:latest";
            pull = "newer";
            autoUpdate = "registry";
            environments = {
              REPO_URL = "https://github.com/${repo}";
              RUNNER_NAME = "${lib.strings.replaceChars ["/"] ["-"] repo}";
              RUNNER_SCOPE = "repo";
              LABELS = "linux,x64";
            };
            secrets = [
              "${githubSecret.ref},type=env,target=ACCESS_TOKEN"
            ];
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock"
            ];
          };
        })
      config.github-runner.repos);
    };
}
