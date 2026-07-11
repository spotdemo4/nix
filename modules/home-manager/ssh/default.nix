{ config, lib, ... }:
let
  cfg = config.trev.programs.ssh;
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
          HostName = "10.10.10.110";
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "build" = {
          HostName = "10.10.10.108";
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "dev" = {
          HostName = "10.10.10.115";
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "etc" = {
          HostName = "10.10.10.114";
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "files" = {
          HostName = "10.10.10.113";
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "game" = {
          HostName = "10.10.10.111";
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "mail" = {
          HostName = "10.10.10.112";
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "media" = {
          HostName = "10.10.10.107";
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "monitor" = {
          HostName = "10.10.10.109";
          User = "trev";
          IdentityFile = "/home/trev/.ssh/id_ed25519";
          ProxyJump = cfg.proxyJump;
        };
        "debian" = {
          HostName = "10.10.10.106";
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
