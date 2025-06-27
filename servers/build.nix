{
  config,
  self,
  pkgs,
  ...
}: {
  imports =
    [
      (self + /hosts/lxc/configuration.nix)
    ]
    ++ map (x: self + /modules/container/${x}.nix) [
      # Containers to import
      "portainer-agent"
      "gitea-act-runner"
      "github-runner"
    ];

  # Github runners
  github-runner = {
    enable = true;
    repos = [
      "spotdemo4/nix"
      "spotdemo4/ts-web"
      "spotdemo4/ts-server"
    ];
  };

  # Forgejo runners
  age.secrets."codeberg".file = self + /secrets/codeberg.age;
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.ts = {
      enable = true;
      name = "my-forgejo-runner-01";
      tokenFile = config.age.secrets."codeberg".path;
      url = "https://codeberg.org";
      labels = [
        "ubuntu-latest:docker://node:24-bookworm"
      ];
    };
  };
}
