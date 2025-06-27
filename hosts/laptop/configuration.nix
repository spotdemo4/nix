# Laptop config
{
  pkgs,
  inputs,
  self,
  hostname,
  ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.catppuccin.nixosModules.catppuccin
      ./hardware-configuration.nix
    ]
    ++ map (x: self + /modules/nixos/${x}.nix) [
      # Programs to import
      "git"
      "gnome-auth-agent"
      "hyprland"
      "pipewire"
      "postgres"
      "sddm"
      "steam"
      "syncthing"
      "tailscale"
      "update"
      "zsh"
    ];

  # Packages to install
  environment.systemPackages = with pkgs; [
    # GUI
    android-studio
    bruno
    dbeaver-bin
    feh
    file-roller
    inputs.trevbar.packages."${system}".default
    jetbrains.datagrip
    jetbrains.idea-community-bin
    kdePackages.kdenlive
    moonlight-qt
    nemo
    nemo-fileroller
    obsidian
    onlyoffice-bin_latest
    plex-desktop
    plexamp
    prismlauncher
    thunderbird
    vesktop

    # CLI
    alejandra
    android-tools
    brightnessctl
    fastfetch
    ffmpeg
    grimblast
    inputs.agenix.packages."${system}".default
    inputs.filebrowser-upload.packages."${system}".default
    libnotify
    mprocs
    ncdu
    nmap
    openconnect
    protonvpn-cli
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
    meslo-lgs-nf
    fira-code
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

  # Nix settings
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

  # Home manager
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
    users = {
      trev.imports = [(self + /users/trev.nix)];
    };
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
        "video"
      ];
      shell = pkgs.zsh;
    };
  };
  age.identityPaths = ["/home/trev/.ssh/id_ed25519"];

  # Update script
  update = {
    enable = true;
    user = "trev";
  };

  # Docker
  virtualisation.docker.enable = true;

  # PGP
  programs.gnupg.agent.enable = true;

  # Upower
  services.upower.enable = true;

  # Allow unfree packages and add overlays
  nixpkgs = {
    config.allowUnfree = true;
  };

  system.stateVersion = "24.05"; # Don't change
}
