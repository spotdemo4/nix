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
    "gitea-runner"
    "portainer/agent.nix"
  ];

  users.users.builder = {
    isNormalUser = true;
    description = "builder";
    openssh.authorizedKeys = {
      keys = (import (self + /secrets/keys.nix)).local ++ [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJPQ+mXNZQNbbFOQhk8t1uwgFk0FOgPRd70PL4mBjdml"
      ];
    };
  };

  nix.extraOptions = ''
    trusted-users = builder
  '';

  # Github runners
  age.secrets."github-runner".file = self + /secrets/github-runner.age;
  services.github-runners = {
    zig-template = {
      enable = true;

      name = "builder";
      replace = true;

      extraLabels = [ "builder" ];
      noDefaultLabels = true;

      user = "builder";

      url = "https://github.com/spotdemo4/zig-template";

      extraPackages = with pkgs; [
        nodejs_24
        nodejs_20
      ];
      nodeRuntimes = [
        "node24"
        "node20"
      ];

      serviceOverrides = {
        MemoryHigh = "12G";
        MemoryMax = "15G";
        CPUWeight = 20;
      };

      tokenFile = config.age.secrets."github-runner".path;
    };
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
