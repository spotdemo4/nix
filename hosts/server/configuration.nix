# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  modulesPath,
  ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ./hardware-configuration.nix
    ]
    ++ map (x: ./../../modules/nixos/${x}.nix) [
      # Programs to import
      "git"
      "updater"
      "zsh"
    ]
    ++ map (x: ./../../modules/scripts/${x}.nix) [
      # Scripts to import
      "update"
    ];

  # Packages to install
  environment.systemPackages = with pkgs; [
    # CLI
    wget
    unzip
    fastfetch
    yt-dlp
    ncdu
    nmap
    btop
    ffmpeg
  ];

  # Nix Settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      sandbox = false;
    };
    extraOptions = ''
      warn-dirty = false
    '';
  };

  # Update script
  update = {
    enable = true;
    hostname = "server";
    user = "trev";
  };

  # Auto update
  updater = {
    enable = true;
  };

  # Networking
  networking.hostName = "nixos-server"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  services.tailscale.enable = true;

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
    extraSpecialArgs = {inherit inputs;};
    users = {
      trev.imports = [./../../users/trev.nix];
    };
  };

  # User accounts
  users.users.trev = {
    isNormalUser = true;
    description = "trev";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  # Docker
  virtualisation.docker.enable = true;

  # Allow unfree packages and add overlays
  nixpkgs = {
    config.allowUnfree = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
