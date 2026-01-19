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
      image = "ghcr.io/trevllc/nix-runner:v0.0.3@sha256:fbf08eaabf0ea21957dd49bc8ec4dbc8024e5500324e298fe0d09997f156b2b9";
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
        "trevllc"
        "spotdemo4/go-template"
        "spotdemo4/svelte-template"
        "spotdemo4/node-template"
        "spotdemo4/rust-template"

        # gitea
        "https://git.quantadev.cc"
      ];
    };

    volumes = {
      nix-action = { };
    };
  };
}
