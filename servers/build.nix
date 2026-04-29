{
  config,
  self,
  pkgs,
  ...
}:
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ map (c: self + /modules/container/${c}) [
    "portainer/agent.nix"
  ];

  users.users = {
    builder = {
      isNormalUser = true;
      description = "remote build user";
      openssh.authorizedKeys = {
        keys = (import (self + /secrets/keys.nix)).local ++ [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJPQ+mXNZQNbbFOQhk8t1uwgFk0FOgPRd70PL4mBjdml"
        ];
      };
    };

    github-runner = {
      isNormalUser = true;
      description = "github runner user";
    };

    gitea-runner = {
      isNormalUser = true;
      description = "gitea runner user";
    };
  };

  # allow users to use nix
  nix.extraOptions = ''
    allowed-users = builder github-runner gitea-runner
  '';

  # make sure nix can't use too much memory when building
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "10G";
    CPUWeight = 20;
  };

  # Github runners
  age.secrets."github-runner".file = self + /secrets/github-runner.age;
  services.github-runners = {
    zig-template = {
      enable = true;
      url = "https://github.com/spotdemo4/zig-template";
      tokenFile = config.age.secrets."github-runner".path;

      name = "builder";
      replace = true;

      extraLabels = [ "builder" ];
      noDefaultLabels = true;

      user = "github-runner";
      extraPackages = with pkgs; [
        curl
        gh
        nodejs_24
        openssl
        wget
      ];
      nodeRuntimes = [
        "node24"
        "node20"
      ];
    };
  };

  # Gitea runners
  age.secrets."gitea-quanta".file = self + /secrets/gitea-quanta.age;
  services.gitea-actions-runner.instances = {
    quanta = {
      enable = true;
      url = "https://git.quantadev.cc";
      tokenFile = config.age.secrets."gitea-quanta".path;

      name = "builder";
      labels = [
        "ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest"
        "ubuntu-24.04:docker://docker.gitea.com/runner-images:ubuntu-24.04"
        "node-24:docker://node:24-bookworm"
        "builder:host"
      ];

      hostPackages = with pkgs; [
        curl
        gh
        nodejs_24
        openssl
        wget
      ];
    };
  };
}
