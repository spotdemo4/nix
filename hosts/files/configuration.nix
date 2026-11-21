{
  config,
  hostname,
  inputs,
  pkgs,
  self,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./containers.nix
    (self + /modules/nixos/knot)
    (self + /modules/nixos/podman-secrets)
    (self + /modules/nixos/update)
    inputs.ci-bridge.nixosModules.default
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
  nix.extraOptions = ''
    warn-dirty = false
  '';

  networking = {
    hostName = hostname;
    firewall.enable = false;
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

  # Runs Forgejo jobs on Blacksmith's GitHub Actions runners
  age.secrets."ci-bridge".file = self + /secrets/ci-bridge.age;
  services.ci-bridge = {
    enable = true;
    forgejo.url = "https://trev.zip";
    github = {
      repo = "trev-zip/bridge";
      private = false;
    };
    labels = [
      "macos-26=blacksmith-6vcpu-macos-26"
      "macos-27=blacksmith-6vcpu-macos-27"
      "ubuntu-26.04-arm=blacksmith-4vcpu-ubuntu-2604-arm"
    ];
    # Sets CI_BRIDGE_FORGEJO_TOKEN and CI_BRIDGE_GITHUB_TOKEN
    environmentFile = config.age.secrets."ci-bridge".path;
  };

  services.journald.upload = {
    enable = true;
    settings.Upload = {
      URL = "http://10.10.10.109:19532";
      Compression = "no";
    };
  };

  users.groups.trev.gid = 1000;
  users.users.trev = {
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
    openssh.authorizedKeys.keys = (import (self + /secrets/keys.nix)).sshClients;
  };

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

  trev.update = {
    enable = true;
    hostname = hostname;
    user = "trev";
  };

  trev.knot = {
    enable = true;
    # trev.tngl.sh
    admins = [ "did:plc:v7ar4oqhsbjmvmmmk4ymx2oq" ];
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";
}
