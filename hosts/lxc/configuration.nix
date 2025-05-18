# Configuration file that applies to every lxc server.
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
      inputs.catppuccin.nixosModules.catppuccin
      ./hardware-configuration.nix
    ]
    ++ map (x: ./../../modules/nixos/${x}.nix) [
      # Programs to import
      "git"
      "openssh"
      "tailscale"
      "zsh"
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

  # Networking
  networking.hostName = "nixos-server"; # Define your hostname.
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
    extraSpecialArgs = {inherit inputs;};
    users = {
      trev.imports = [./../../users/trev-server.nix];
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
          "docker"
        ];
        packages = with pkgs; [];
        shell = pkgs.zsh;
        inherit (import ./../../modules/nixos/keys.nix) openssh;
      };
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

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
