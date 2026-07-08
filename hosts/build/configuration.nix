{
  config,
  self,
  pkgs,
  ...
}:
{
  imports = [
    (self + /templates/lxc)
    ./hardware-configuration.nix
  ]
  ++ map (c: self + /modules/nixos/${c}) [
    "niks3"
  ]
  ++ map (c: self + /modules/container/${c}) [
    "portainer/agent.nix"
  ];

  # Add build users
  users.users = {
    builder = {
      isNormalUser = true;
      description = "remote build user";
      extraGroups = [ "docker" ];
      openssh.authorizedKeys = {
        keys = (import (self + /secrets/keys.nix)).local ++ [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJPQ+mXNZQNbbFOQhk8t1uwgFk0FOgPRd70PL4mBjdml"
        ];
      };
    };
    github-runner = {
      isNormalUser = true;
      description = "github runner user";
      extraGroups = [ "docker" ];
    };
    gitea-runner = {
      isNormalUser = true;
      description = "gitea runner user";
      extraGroups = [ "docker" ];
    };
  };

  # allow users to use nix
  nix.extraOptions = ''
    allowed-users = github-runner gitea-runner
    trusted-users = builder trev
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
        docker
        docker-compose
        gawk
        gh
        hostname-debian
        nodejs_24
        openssl
        procps
        wget
      ];
      nodeRuntimes = [
        "node24"
      ];
    };
    chromium-android-desktop = {
      enable = true;
      url = "https://github.com/spotdemo4/chromium-android-desktop";
      tokenFile = config.age.secrets."github-runner".path;
      name = "builder";
      replace = true;
      extraLabels = [ "builder" ];
      noDefaultLabels = true;
      user = "github-runner";
      workDir = "/chromium";
      extraPackages = with pkgs; [
        curl
        docker
        docker-compose
        gawk
        gh
        hostname-debian
        nodejs_24
        openssl
        procps
        wget
      ];
      nodeRuntimes = [
        "node24"
      ];
    };
  };

  # Forgejo runners
  age.secrets."forgejo".file = self + /secrets/forgejo.age;
  age.secrets."forgejo-org".file = self + /secrets/forgejo-org.age;
  age.secrets."forgejo-template".file = self + /secrets/forgejo-template.age;
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances = {
      trev = {
        enable = true;
        url = "https://trev.zip/";
        tokenFile = config.age.secrets."forgejo".path;
        name = "builder";
        labels = [
          "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest@sha256:58ea92624c7c09582e05594d95488331045053d3a3f34cf09649f2a32313a614"
          "ubuntu-24.04:docker://gitea/runner-images:ubuntu-24.04@sha256:58ea92624c7c09582e05594d95488331045053d3a3f34cf09649f2a32313a614"
          "nixos-latest:docker://nixos/nix:2.34.8@sha256:1a711b619c8a713eff32c3f8d8781b3b4d0130cb91c0a57f67e87abfeeb90b01"
        ];
        settings = {
          runner = {
            capacity = 2;
          };
          container = {
            network = "host";
            privileged = true;
            docker_host = "unix:///run/podman/podman.sock";
          };
        };
      };
      org = {
        enable = true;
        url = "https://trev.zip/";
        tokenFile = config.age.secrets."forgejo-org".path;
        name = "builder";
        labels = [
          "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest@sha256:58ea92624c7c09582e05594d95488331045053d3a3f34cf09649f2a32313a614"
          "ubuntu-24.04:docker://gitea/runner-images:ubuntu-24.04@sha256:58ea92624c7c09582e05594d95488331045053d3a3f34cf09649f2a32313a614"
          "nixos-latest:docker://nixos/nix:2.34.8@sha256:1a711b619c8a713eff32c3f8d8781b3b4d0130cb91c0a57f67e87abfeeb90b01"
        ];
        settings = {
          runner = {
            capacity = 2;
          };
          container = {
            network = "host";
            privileged = true;
            docker_host = "unix:///run/podman/podman.sock";
          };
        };
      };
      template = {
        enable = true;
        url = "https://trev.zip/";
        tokenFile = config.age.secrets."forgejo-template".path;
        name = "builder";
        labels = [
          "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest@sha256:58ea92624c7c09582e05594d95488331045053d3a3f34cf09649f2a32313a614"
          "ubuntu-24.04:docker://gitea/runner-images:ubuntu-24.04@sha256:58ea92624c7c09582e05594d95488331045053d3a3f34cf09649f2a32313a614"
          "nixos-latest:docker://nixos/nix:2.34.8@sha256:1a711b619c8a713eff32c3f8d8781b3b4d0130cb91c0a57f67e87abfeeb90b01"
        ];
        settings = {
          runner = {
            capacity = 2;
          };
          container = {
            network = "host";
            privileged = true;
            docker_host = "unix:///run/podman/podman.sock";
          };
        };
      };
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
    };
  };
}
