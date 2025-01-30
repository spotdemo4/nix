# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.catppuccin.nixosModules.catppuccin
    ./hardware-configuration.nix
  ] ++ map (x: ./../../modules/nixos/${x}.nix) [
    # Programs to import
    "git"
    "gnome-auth-agent"
    "hyprland"
    "pipewire"
    "postgres"
    "sddm"
    "steam"
    "syncthing"
    "zsh"
    "virt-manager"
    "updater"
  ] ++ map (x: ./../../modules/scripts/${x}.nix) [
    # Scripts to import
    "update"
    "rebuild"
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
    dbeaver-bin
    android-studio
    plexamp
    thunderbird
    kdePackages.kdenlive
    bruno
    onlyoffice-bin_latest
    prismlauncher
    moonlight-qt
    inputs.zen-browser.packages."${system}".default
    obs-studio
    heroic
    inputs.trevbar.packages."${system}".default

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
    libnotify

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
    settings.experimental-features = [ "nix-command" "flakes" ];
    extraOptions = ''
      warn-dirty = false
    '';
  };

  # Auto update
  updater = {
    enable = true;
    hostname = "desktop";
  };

  # Networking
  networking.hostName = "nixos-desktop"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  services.tailscale.enable = true;

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
    extraSpecialArgs = { inherit inputs; };
    users = {
      trev.imports = [ ./trev.nix ];
    };
  };

  # User accounts
  users.users.trev = {
    isNormalUser = true;
    description = "trev";
    extraGroups = [ "networkmanager" "wheel" "docker" "scanner" "lp" "libvirtd" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  # Docker
  virtualisation.docker.enable = true;

  # Allow unfree packages and add overlays
  nixpkgs = {
    config = {
      allowUnfree = true;
      rocmSupport = true;
    };
    overlays = [ 
      inputs.catppuccin-vsc.overlays.default
    ];
  };

  # Make Ollama use amd gpu 
  # services.ollama.rocmOverrideGfx = "11.0.0";

  # Scanner support
  hardware.sane = {
    enable = true;
    brscan5.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
