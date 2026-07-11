{
  hostname,
  pkgs,
  self,
  ...
}:
{
  imports = [
    ../home-manager.nix
    ../users/trev.nix
  ]
  ++ map (module: self + /modules/nixos/${module}) [
    "git"
    "openssh"
    "update"
    "zsh"
  ];

  environment.systemPackages = with pkgs; [
    fastfetch
    ffmpeg
    ncdu
    nmap
    unzip
    wget
    yt-dlp
    zip
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
      extra-substituters = [
        "https://nix.trev.zip"
      ];
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

  update = {
    enable = true;
    user = "trev";
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";
}
