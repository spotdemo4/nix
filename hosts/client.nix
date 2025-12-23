# Base config for every client (desktop, laptop, etc)
{
  hostname,
  inputs,
  pkgs,
  self,
  ...
}:
{
  imports = map (x: self + /modules/nixos/${x}.nix) [
    # Programs to import
    "clickhouse"
    "git"
    "gnome-auth-agent"
    "hyprland"
    "openssh"
    "pipewire"
    "postgres"
    "steam"
    "syncthing"
    "tailscale"
    "update"
    "virt-manager"
    "zsh"
  ];

  # Packages to install
  environment.systemPackages = with pkgs; [
    # GUI
    android-studio
    bruno
    feh
    file-roller
    heroic
    inputs.trevbar.packages."${stdenv.hostPlatform.system}".default
    jetbrains.datagrip
    jetbrains.idea
    kdePackages.kdenlive
    monero-gui
    moonlight-qt
    nemo
    nemo-fileroller
    obs-studio
    obsidian
    onlyoffice-desktopeditors
    parsec-bin
    plexamp
    prismlauncher
    thunderbird
    tor-browser
    vesktop

    # CLI
    alejandra
    android-tools
    attic-client
    claude-code
    fastfetch
    ffmpeg
    file
    grimblast
    inputs.agenix.packages."${stdenv.hostPlatform.system}".default
    jq
    libnotify
    mprocs
    ncdu
    nmap
    openconnect
    protonvpn-gui
    unzip
    wget
    wl-clipboard
    yt-dlp
    zip

    # Applets
    networkmanagerapplet
    pavucontrol
  ];

  # Fonts to install
  fonts.packages = with pkgs; [
    fira-code
    meslo-lgs-nf
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # -- SYSTEM CONFIGURATION --

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.timeout = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # TTY
  catppuccin.tty = {
    enable = true;
    flavor = "mocha";
  };

  # Nix Settings
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

  # Networking
  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Security
  security.polkit.enable = true;

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

  # User accounts
  users = {
    users.trev = {
      isNormalUser = true;
      description = "trev";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "scanner"
        "lp"
        "libvirtd"
        "video"
        "render"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys =
        let
          nixKeys = import (self + /secrets/keys.nix);
        in
        {
          keys = nixKeys.local;
        };
    };
  };
  age.identityPaths = [ "/home/trev/.ssh/id_ed25519" ];

  # Update script
  update = {
    enable = true;
    user = "trev";
  };

  # Docker
  virtualisation.docker.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # PGP
  programs.gnupg.agent.enable = true;

  system.stateVersion = "24.05"; # Don't change
}
