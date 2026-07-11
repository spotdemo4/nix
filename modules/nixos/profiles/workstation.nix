{
  config,
  inputs,
  pkgs,
  self,
  ...
}:
{
  imports = [
    ./common.nix
    ./development.nix
  ]
  ++ map (module: self + /modules/nixos/${module}) [
    "gnome-auth-agent"
    "hyprland"
    "niks3"
    "pipewire"
    "postgres"
    "steam"
    "syncthing"
    "tailscale"
    "virt-manager"
  ];

  environment.systemPackages = with pkgs; [
    # GUI
    android-studio
    bruno
    feh
    file-roller
    gimp
    heroic
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
    trev.helium
    vesktop
    inputs.trevbar.packages."${stdenv.hostPlatform.system}".default

    # CLI
    android-tools
    grimblast
    igsc
    libnotify
    openconnect
    proton-vpn-cli
    stunnel
    trev.codex-commit
    wl-clipboard

    # Applets
    networkmanagerapplet
    pavucontrol
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

  catppuccin.tty = {
    enable = true;
    flavor = "mocha";
  };

  age.secrets."builder-key".file = self + /secrets/builder-key.age;
  age.identityPaths = [ "/home/trev/.ssh/id_ed25519" ];

  nix = {
    settings.builders-use-substitutes = true;
    buildMachines = [
      {
        hostName = "build";
        sshUser = "builder";
        sshKey = config.age.secrets."builder-key".path;
        system = "x86_64-linux";
        protocol = "ssh-ng";
        maxJobs = 20;
      }
    ];
  };

  networking = {
    networkmanager.enable = true;
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };

  security = {
    polkit.enable = true;
    pam.services.hyprlock = { };
  };

  users.users.trev.extraGroups = [
    "networkmanager"
    "wheel"
    "docker"
    "scanner"
    "lp"
    "libvirtd"
    "video"
    "render"
  ];

  home-manager.backupFileExtension = "backup";

  virtualisation.docker.enable = true;
  programs.gnupg.agent.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;
}
