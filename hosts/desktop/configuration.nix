# Desktop config
{
  pkgs,
  inputs,
  self,
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
      "virt-manager"
      "zsh"
    ];

  # Packages to install
  environment.systemPackages = with pkgs; [
    # GUI
    nemo
    nemo-fileroller
    file-roller
    vesktop
    feh
    obsidian
    jetbrains.idea-community-bin
    android-studio
    plexamp
    thunderbird
    kdePackages.kdenlive
    bruno
    onlyoffice-bin_latest
    prismlauncher
    moonlight-qt
    obs-studio
    heroic
    inputs.trevbar.packages."${system}".default
    jetbrains.datagrip
    tor-browser
    monero-gui

    # CLI
    wget
    unzip
    zip
    fastfetch
    grimblast
    android-tools
    yt-dlp
    openconnect
    ncdu
    nmap
    btop
    ffmpeg
    inputs.filebrowser-upload.packages."${system}".default
    inputs.agenix.packages."${system}".default
    libnotify
    alejandra
    protonvpn-cli

    # Applets
    networkmanagerapplet
    pavucontrol
  ];

  # Fonts to install
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
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

  # Nix Settings
  nix = {
    settings = {
      # Not working atm, need determinate nix
      # lazy-trees = true;
      experimental-features = ["nix-command" "flakes"];
      trusted-users = [
        "root"
        "trev"
      ];
    };

    extraOptions = ''
      warn-dirty = false
    '';
  };

  # Update script
  update = {
    enable = true;
    hostname = "desktop";
    user = "trev";
  };

  # Networking
  networking.hostName = "nixos-desktop"; # Define your hostname.
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
      inherit inputs;
      inherit self;
    };
    users = {
      trev.imports = [(self + /users/trev.nix)];
    };
  };

  # User accounts
  users.users.trev = {
    isNormalUser = true;
    description = "trev";
    extraGroups = ["networkmanager" "wheel" "docker" "scanner" "lp" "libvirtd"];
    shell = pkgs.zsh;
  };
  age.identityPaths = ["/home/trev/.ssh/id_ed25519"];

  # Docker
  virtualisation.docker.enable = true;

  # Allow unfree packages and add overlays
  nixpkgs = {
    config = {
      allowUnfree = true;
      rocmSupport = true;
    };
  };

  # PGP
  programs.gnupg.agent.enable = true;

  # Scanner support
  hardware.sane = {
    enable = true;
    # brscan5.enable = true;
  };

  system.stateVersion = "24.05"; # Don't change
}
