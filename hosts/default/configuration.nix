# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.catppuccin.nixosModules.catppuccin
    ./hardware-configuration.nix

    # Programs
    ../../modules/nixos/hyprland.nix
    ../../modules/nixos/zsh.nix
    ../../modules/nixos/sddm.nix
    ../../modules/nixos/pipewire.nix
    ../../modules/nixos/gnome-auth-agent.nix
    ../../modules/nixos/git.nix
    ../../modules/nixos/syncthing.nix

    # Scripts
    ../../modules/scripts/update.nix
  ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.extraEntries."arch.conf" = ''
    title Arch Linux
    linux /vmlinuz-linux
    initrd /initramfs-linux.img
    options root=/dev/nvme0n1p4 rw add_efi_memmap
  '';
  boot.loader.timeout = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Console
  console.catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Auto Upgrade
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  # Networking
  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

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
  users.users.trev = {
    isNormalUser = true;
    description = "trev";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  # Home manager
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      trev.imports = [ ./trev.nix ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run nix search wget
  environment.systemPackages = with pkgs; [
    wget
    unzip
    fastfetch
    cinnamon.nemo
    cinnamon.nemo-fileroller
    gnome.file-roller
    vesktop
    fastfetch
    feh
    grimblast
    obsidian
    jetbrains.datagrip
    jetbrains.idea-community-bin
    android-studio
    android-tools
    plexamp
    yt-dlp
    thunderbird

    # BS QT shit
    kdePackages.qt6ct
    libsForQt5.qt5ct
    kdePackages.qtstyleplugin-kvantum

    # Applets
    networkmanagerapplet
    pavucontrol
    
    # Hyprlandia
    hyprcursor
    hyprpaper
  ];

  # Fonts
  fonts.packages = with pkgs; [
    meslo-lgs-nf
    fira-code
  ];

  # Programs
  programs.direnv.enable = true;
  programs.steam.enable = true;
  hyprland-nix.enable = true;
  zsh-nix.enable = true;
  sddm-nix.enable = true;
  pipewire-nix.enable = true;
  gnome-auth-agent-nix.enable = true;
  git-nix.enable = true;
  syncthing-nix.enable = true;

  # Scripts
  update-script.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
