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
      "gitea-runner"
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

  # Gitea runners
  age.secrets."gitea".file = self + /secrets/gitea.age;
  age.secrets."gitea-quanta".file = self + /secrets/gitea-quanta.age;
  gitea-runner = {
    enable = true;
    instances = {
      gitea-ts = {
        url = "https://gitea.com";
        tokenFile = config.age.secrets."gitea".path;
      };
      gitea-quanta = {
        url = "https://git.quantadev.cc";
        tokenFile = config.age.secrets."gitea-quanta".path;
      };
    };
  };

  # Forgejo runners
  age.secrets."codeberg".file = self + /secrets/codeberg.age;
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances = {
      forgejo-ts = {
        enable = true;
        name = "forgejo-ts";
        tokenFile = config.age.secrets."codeberg".path;
        url = "https://codeberg.org";
        labels = [
          "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:runner-latest"
        ];
      };
    };
  };
}
