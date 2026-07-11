{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  mcpSecretFiles = {
    context7 = self + /secrets/context7.age;
    forgejo-mcp = self + /secrets/forgejo-mcp.age;
    github = self + /secrets/github.age;
    kagi = self + /secrets/kagi.age;
  };
in
{
  imports = [
    ./hardware.nix
    (self + /modules/nixos/niks3)
    (self + /modules/nixos/podman-secrets)
    (self + /modules/nixos/update)
  ];

  environment.systemPackages = with pkgs; [
    attic-client
    claude-code
    codex
    fastfetch
    ffmpeg
    file
    iperf
    jq
    kitty
    mprocs
    ncdu
    nix-tree
    nmap
    openssl
    ripgrep
    traceroute
    unzip
    wget
    yt-dlp
    zip
    inputs.agenix.packages."${stdenv.hostPlatform.system}".default
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "trev"
      ];
      extra-substituters = [ "https://nix.trev.zip" ];
      extra-trusted-public-keys = [
        "trev:I39N/EsnHkvfmsbx8RUW+ia5dOzojTQNCTzKYij1chU="
      ];
      fallback = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = "05:00";
    };
    extraOptions = ''
      warn-dirty = false
    '';
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
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
  };

  catppuccin = {
    enable = true;
    autoEnable = false;
  };

  programs = {
    git = {
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
    gnupg.agent.enable = true;
    nix-ld.enable = true;
    zsh.enable = true;
  };

  services = {
    cadvisor = {
      enable = true;
      port = 8069;
      listenAddress = "0.0.0.0";
    };
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    journald.upload = {
      enable = true;
      settings.Upload.URL = "http://10.10.10.109:9428/insert/journald";
    };
  };

  users = {
    groups.trev.gid = 1000;
    users.trev = {
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
  };

  age.secrets =
    lib.mapAttrs (_: file: {
      inherit file;
      owner = "trev";
      group = "trev";
      mode = "0400";
    }) mcpSecretFiles
    // {
      gpg = {
        file = self + /secrets/gpg.age;
        path = "/home/trev/.gnupg/private-keys-v1.d/02F9D60E16452DC74C0FBFC2ECA9E20D1D75C89C.key";
        owner = "trev";
        group = "trev";
        mode = "0600";
        symlink = false;
      };
    };

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
    users.trev = {
      imports = [ ./home-manager.nix ];
      trev.mcp.secretPaths = lib.mapAttrs (name: _: config.age.secrets.${name}.path) mcpSecretFiles;
    };
  };

  virtualisation = {
    podman = {
      enable = true;
      autoPrune = {
        enable = true;
        flags = [ "--all" ];
      };
    };
    quadlet = {
      autoEscape = true;
      autoUpdate.enable = true;
    };
  };

  trev = {
    niks3.enable = true;
    podman-secrets.enable = true;
    update = {
      enable = true;
      hostname = hostname;
      user = "trev";
    };
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";
}
