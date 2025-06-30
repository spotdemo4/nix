{
  config,
  self,
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
      "forgejo-runner"
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
  age.secrets."codeberg".file = self + /secrets/codeberg.age;
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
      forgejo-ts = {
        url = "https://codeberg.org";
        tokenFile = config.age.secrets."codeberg".path;
      };
    };
  };
}
