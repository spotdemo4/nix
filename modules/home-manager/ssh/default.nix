{
  config,
  lib,
  self,
  ...
}:
let
  cfg = config.trev.programs.ssh;
  lan = import (self + /lib/lan);
in
{
  options.trev.programs.ssh = {
    enable = lib.mkEnableOption "Trev's SSH configuration";
    proxyJump = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "gateway";
      description = "Proxy host used to reach internal servers.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "gateway" = {
          HostName = "trev.xyz";
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
        };
        "bench" = {
          HostName = lan.addresses.bench;
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "build" = {
          HostName = lan.addresses.build;
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "dev" = {
          HostName = lan.addresses.dev;
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "etc" = {
          HostName = lan.addresses.etc;
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "files" = {
          HostName = lan.addresses.files;
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "game" = {
          HostName = lan.addresses.game;
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "mail" = {
          HostName = lan.addresses.mail;
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "media" = {
          HostName = lan.addresses.media;
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "monitor" = {
          HostName = lan.addresses.monitor;
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "debian" = {
          HostName = lan.addresses.debian;
          User = "root";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "nixaws" = {
          HostName = "localhost";
          Port = 2222;
          User = "root";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
          CheckHostIP = "no";
        };
      };
    };
  };
}
