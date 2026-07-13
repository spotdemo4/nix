{
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
  imports = [ ./hardware.nix ];

  determinate.enable = false;
  documentation.enable = false;

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
    gc.automatic = false;
    optimise.automatic = false;
    extraOptions = ''
      warn-dirty = false
    '';
  };

  networking = {
    hostName = hostname;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    hosts."10.10.10.105" = [ "nix.trev.zip" ];
  };

  time.timeZone = "America/Detroit";
  i18n.defaultLocale = "en_US.UTF-8";

  services = {
    fstrim.enable = false;
    journald.extraConfig = ''
      Storage=volatile
    '';
    logrotate.enable = false;
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };

  systemd = {
    oomd.enable = false;
    services."systemd-tmpfiles-clean".enable = false;
    timers."systemd-tmpfiles-clean".enable = false;
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

  system.stateVersion = "24.05";
}
