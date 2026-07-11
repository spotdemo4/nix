{
  config,
  hostname,
  inputs,
  pkgs,
  self,
  ...
}:
{
  imports = [
    ./hardware.nix
    (self + /modules/nixos/gnome-auth-agent)
    (self + /modules/nixos/niks3)
    (self + /modules/nixos/tailscale)
    (self + /modules/nixos/update)
  ];

  environment.systemPackages = with pkgs; [
    android-studio
    android-tools
    attic-client
    bruno
    claude-code
    codex
    fastfetch
    feh
    ffmpeg
    file
    file-roller
    gimp
    grimblast
    heroic
    igsc
    jetbrains.datagrip
    jetbrains.idea
    jq
    kdePackages.kdenlive
    libnotify
    monero-gui
    moonlight-qt
    mprocs
    ncdu
    nemo
    nemo-fileroller
    networkmanagerapplet
    nix-tree
    nmap
    nvtopPackages.intel
    obs-studio
    obsidian
    onlyoffice-desktopeditors
    openconnect
    openssl
    parsec-bin
    pavucontrol
    plexamp
    prismlauncher
    proton-vpn-cli
    ripgrep
    stunnel
    thunderbird
    tor-browser
    trev.codex-commit
    trev.helium
    unzip
    vesktop
    wget
    wl-clipboard
    yt-dlp
    zip
    inputs.agenix.packages."${stdenv.hostPlatform.system}".default
    inputs.trevbar.packages."${stdenv.hostPlatform.system}".default
  ];
  fonts.packages = with pkgs; [
    fira-code
    meslo-lgs-nf
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  boot.loader = {
    systemd-boot.enable = true;
    timeout = 10;
    efi.canTouchEfiVariables = true;
  };
  catppuccin = {
    enable = true;
    autoEnable = false;
    tty = {
      enable = true;
      flavor = "mocha";
    };
  };

  age.secrets."builder-key".file = self + /secrets/builder-key.age;
  age.identityPaths = [ "/home/trev/.ssh/id_ed25519" ];
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "trev"
    ];
    extra-substituters = [ "https://nix.trev.zip" ];
    extra-trusted-public-keys = [ "trev:I39N/EsnHkvfmsbx8RUW+ia5dOzojTQNCTzKYij1chU=" ];
    fallback = true;
    builders-use-substitutes = true;
  };
  nix.buildMachines = [
    {
      hostName = "build";
      sshUser = "builder";
      sshKey = config.age.secrets."builder-key".path;
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 20;
    }
  ];
  nix.distributedBuilds = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.optimise = {
    automatic = true;
    dates = "05:00";
  };
  nix.extraOptions = ''
    warn-dirty = false
  '';

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    firewall.enable = false;
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };
  time.timeZone = "America/Detroit";
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

  programs = {
    dconf.enable = true;
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
    hyprland.enable = true;
    nix-ld.enable = true;
    steam = {
      enable = true;
      extraPackages = [ pkgs.gamescope ];
    };
    virt-manager.enable = true;
    zsh.enable = true;
  };
  security = {
    polkit.enable = true;
    pam.services.hyprlock = { };
    rtkit.enable = true;
  };

  services = {
    blueman.enable = true;
    gnome.gnome-keyring.enable = true;
    greetd = {
      enable = true;
      settings.default_session = {
        user = "trev";
        command = "${pkgs.greetd}/bin/agreety --cmd start-hyprland";
      };
    };
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
    };
    syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = "trev";
      dataDir = "/home/trev";
      settings = {
        devices.server = {
          id = "6Y5HP4G-VVTITOU-AXUS3T7-NCM33QB-3GRVWVE-PKD6BEG-NS5L2HV-X4FDGA2";
          name = "server";
          addresses = [
            "quic://192.96.218.133:22000"
            "tcp://192.96.218.133:22000"
          ];
        };
        folders.codex = {
          id = "7g6xq-7j2k4";
          devices = [ "server" ];
          label = "codex";
          path = "~/.codex";
          ignorePatterns = [
            "!auth.json"
            "**"
          ];
        };
      };
    };
    upower.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  virtualisation.docker.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };

  users.users.trev = {
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
    openssh.authorizedKeys.keys = (import (self + /secrets/keys.nix)).sshClients;
  };
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
    backupFileExtension = "backup";
    users = {
      root.imports = [ ./root-home-manager.nix ];
      trev.imports = [ ./home-manager.nix ];
    };
  };
  trev = {
    gnome-auth-agent.enable = true;
    niks3.enable = true;
    tailscale.enable = true;
    update = {
      enable = true;
      hostname = hostname;
      user = "trev";
    };
  };
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";
}
