{self, ...}: {
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
}
