# Base config for every server (LXC, bare-metal, etc)
{
  hostname,
  inputs,
  pkgs,
  self,
  ...
}: {
  imports =
    map (x: self + /modules/nixos/${x}.nix) [
      # Programs to import
      "cadvisor"
      "git"
      "openssh"
      "tailscale"
      "update"
      "zsh"
    ]
    ++ map (x: self + /modules/util/${x}) [
      # Utility modules
      "secrets"
    ];

  # Packages to install
  environment.systemPackages = with pkgs; [
    # CLI
    fastfetch
    ffmpeg
    ncdu
    nmap
    unzip
    wget
    yt-dlp
    zip

    # GUI technically but needed for ssh
    kitty
  ];

  # Nix Settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
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

  # Networking
  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  # Time zone
  time.timeZone = "America/Detroit";

  # Internationalisation properties
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

  # Home manager
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
    users = {
      trev.imports = [(self + /users/trev-server.nix)];
    };
  };

  # Users & groups
  users = {
    groups = {
      trev = {
        gid = 1000;
      };
    };

    users = {
      trev = {
        isNormalUser = true;
        uid = 1000;
        description = "trev";

        group = "trev";
        extraGroups = [
          "networkmanager"
          "wheel"
          "podman"
          "video"
          "render"
        ];
        shell = pkgs.zsh;
        openssh.authorizedKeys = let
          nixKeys = import (self + /secrets/keys.nix);
        in {
          keys = nixKeys.local;
        };
      };
    };
  };

  # Update script
  update = {
    enable = true;
    user = "trev";
  };

  # Podman
  virtualisation.podman = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [
        "--all"
      ];
    };
  };

  # Quadlet
  virtualisation.quadlet = {
    autoEscape = true;
    autoUpdate = {
      enable = true;
    };
  };

  # Allow unfree packages and add overlays
  nixpkgs = {
    config.allowUnfree = true;
  };

  system.stateVersion = "24.05"; # Don't change
}
