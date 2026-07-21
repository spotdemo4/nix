{
  config,
  hostname,
  inputs,
  self,
  pkgs,
  ...
}:
let
  keys = import (self + /secrets/keys.nix);
in
{
  imports = [
    ./hardware.nix
    ./containers.nix
    (self + /modules/nixos/niks3)
    (self + /modules/nixos/podman-secrets)
    (self + /modules/nixos/update)
  ];

  environment.systemPackages = with pkgs; [
    fastfetch
    ffmpeg
    iperf
    kitty
    ncdu
    nmap
    traceroute
    unzip
    wget
    yt-dlp
    zip
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "trev"
    ];
    extra-substituters = [ "https://nix.trev.zip" ];
    extra-trusted-public-keys = [ "trev:I39N/EsnHkvfmsbx8RUW+ia5dOzojTQNCTzKYij1chU=" ];
    fallback = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.optimise = {
    automatic = true;
    dates = "05:00";
  };

  networking = {
    hostName = hostname;
    firewall.enable = false;
    hosts."10.10.10.105" = [
      "trev.xyz"
      "trev.zip"
      "trev.kiwi"
      "trev.rs"
      "cache.trev.zip"
      "s3.trev.zip"
      "nix.trev.zip"
      "niks3.trev.zip"
    ];
  };

  time.timeZone = "America/Detroit";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  catppuccin = {
    enable = true;
    autoEnable = false;
  };

  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      user = {
        name = "trev";
        email = "me@trev.xyz";
        signingkey = "3AAF87E0B1A2AC36";
      };
      commit.gpgsign = "true";
      tag.gpgSign = "true";
      safe.directory = "/etc/nixos";
    };
  };
  programs.zsh.enable = true;

  services.cadvisor = {
    enable = true;
    port = 8069;
    listenAddress = "0.0.0.0";
  };
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  services.journald.upload = {
    enable = true;
    settings.Upload.URL = "http://10.10.10.109:9428/insert/journald";
  };

  users.groups.trev.gid = 1000;

  # Add build users
  users.users = {
    trev = {
      isNormalUser = true;
      uid = 1000;
      description = "trev";
      group = "trev";
      extraGroups = [
        "wheel"
        "podman"
        "video"
        "render"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys.sshClients ++ [ keys.devTrev ];
    };
    builder = {
      isNormalUser = true;
      description = "remote build user";
      extraGroups = [ "docker" ];
      openssh.authorizedKeys = {
        keys = keys.local ++ [
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
    warn-dirty = false
    allowed-users = github-runner gitea-runner
    trusted-users = builder trev
  '';

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
    users.trev.imports = [ ./home-manager.nix ];
  };

  virtualisation.podman = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
    };
  };
  virtualisation.quadlet = {
    autoEscape = true;
    autoUpdate.enable = true;
  };

  trev = {
    niks3.enable = true;
    update = {
      enable = true;
      hostname = hostname;
      user = "trev";
    };
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";

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
          "nixos-latest:docker://nixos/nix:2.35.1@sha256:377d4887aca98f0dfa12971c1ea6d6a625a435d8b610d4c95a436843da6fbfd1"
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
          "nixos-latest:docker://nixos/nix:2.35.1@sha256:377d4887aca98f0dfa12971c1ea6d6a625a435d8b610d4c95a436843da6fbfd1"
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
          "nixos-latest:docker://nixos/nix:2.35.1@sha256:377d4887aca98f0dfa12971c1ea6d6a625a435d8b610d4c95a436843da6fbfd1"
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
