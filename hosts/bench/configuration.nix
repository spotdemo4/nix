{
  config,
  hostname,
  lib,
  pkgs,
  self,
  ...
}:
let
  keys = import (self + /secrets/keys.nix);
in
{
  imports = [
    ./ci.nix
    ./hardware.nix
    ./partition.nix
    (self + /modules/nixos/update)
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  determinate.enable = false;
  documentation.enable = false;

  catppuccin = {
    enable = false;
    autoEnable = false;
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = with pkgs; [
      git
      hyperfine
      numactl
    ];
  };

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
      extra-substituters = [ "https://nix.trev.zip" ];
      extra-trusted-public-keys = [
        "trev:I39N/EsnHkvfmsbx8RUW+ia5dOzojTQNCTzKYij1chU="
      ];
      fallback = true;
    };
    extraOptions = ''
      warn-dirty = false
    '';
  };

  # keep cores at their highest clock (boost is disabled in partition.nix)
  powerManagement.cpuFreqGovernor = "performance";

  networking = {
    hostName = hostname;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  time.timeZone = "America/Detroit";
  i18n.defaultLocale = "en_US.UTF-8";

  services = {
    fstrim.enable = false;
    journald.settings.Journal.Storage = "volatile";
    logrotate.enable = false;
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    tailscale.enable = true;
  };

  systemd = {
    oomd.enable = false;
    services."systemd-tmpfiles-clean".enable = false;
    timers."systemd-tmpfiles-clean".enable = false;
  };

  trev.update = {
    enable = true;
    inherit hostname;
    user = "trev";
    idle = {
      enable = true;
      check = [
        (lib.getExe config.bench.run)
        "--idle"
      ];
    };
    # switch like a benchmark on every core: once running CI jobs finish, and keeping
    # benchmarks and new CI jobs waiting until it's done
    wrapper = [
      (lib.getExe config.bench.run)
      "--cores"
      (toString (lib.length config.bench.cores))
      "--"
    ];
  };

  users = {
    groups.trev.gid = 1000;
    users.trev = {
      isNormalUser = true;
      uid = 1000;
      description = "trev";
      group = "trev";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = keys.sshClients ++ [ keys.devTrev ];
    };
  };

  system.stateVersion = "26.05";
}
