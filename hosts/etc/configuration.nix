{
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
  nix.extraOptions = ''
    warn-dirty = false
  '';

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

  trev.podman-secrets.enable = true;
  trev.update = {
    enable = true;
    hostname = hostname;
    user = "trev";
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";
}
