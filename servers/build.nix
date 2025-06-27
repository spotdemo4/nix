{
  self,
  pkgs,
  config,
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
  containers.forgejo-runner = {
    autoStart = true;
    config = {
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

      virtualisation.podman = {
        enable = true;
        autoPrune = {
          enable = true;
          flags = [
            "--all"
          ];
        };
      };

      system.stateVersion = "24.05";
    };
  };

  # Gitea runners
  age.secrets."gitea".file = self + /secrets/gitea.age;
  containers.gitea-runner = {
    autoStart = true;
    config = {
      services.gitea-actions-runner = {
        package = pkgs.gitea-actions-runner;
        instances.ts = {
          enable = true;
          name = "nix-build";
          tokenFile = config.age.secrets."gitea".path;
          url = "https://gitea.com";
          labels = [
            "ubuntu-latest:docker://node:24-bookworm"
          ];
        };
      };

      virtualisation.podman = {
        enable = true;
        autoPrune = {
          enable = true;
          flags = [
            "--all"
          ];
        };
      };

      system.stateVersion = "24.05";
    };
  };
}
