{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes;
  inherit (config) secrets;
in
{
  secrets = {
    "org-token".file = self + /secrets/org-token.age;
    "repo-token".file = self + /secrets/repo-token.age;
    "quantadev-token".file = self + /secrets/quantadev-token.age;
  };

  virtualisation.quadlet = {
    containers."nix-action".containerConfig = {
      image = "ghcr.io/trevllc/nix-runner:v0.0.4@sha256:1d9b708391fc2937fe59310e8e608bf69c6a061461403335a5c90f7e083cf4e9";
      pull = "missing";
      secrets = [
        "${secrets."org-token".env},target=ORG_TOKEN"
        "${secrets."repo-token".env},target=REPO_TOKEN"
        "${secrets."quantadev-token".env},target=GITEA_TOKEN"
      ];
      volumes = [
        "${volumes."nix-action".ref}:/backup"
      ];
      exec = [
        # github
        "https://github.com/trevllc"
        "https://github.com/spotdemo4/go-template"
        "https://github.com/spotdemo4/svelte-template"
        "https://github.com/spotdemo4/node-template"
        "https://github.com/spotdemo4/rust-template"

        # gitea
        "https://git.quantadev.cc"
      ];
    };

    volumes = {
      nix-action = { };
    };
  };
}
