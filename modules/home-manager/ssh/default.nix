{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "gateway" = {
        HostName = "trev.xyz";
        User = "trev";
        IdentityFile = "/home/trev/.ssh/id_ed25519";
      };
      "build" = {
        HostName = "10.10.10.108";
        User = "trev";
        IdentityFile = "/home/trev/.ssh/id_ed25519";
        ProxyJump = "gateway";
      };
      "etc" = {
        HostName = "10.10.10.114";
        User = "trev";
        IdentityFile = "/home/trev/.ssh/id_ed25519";
        ProxyJump = "gateway";
      };
      "files" = {
        HostName = "10.10.10.113";
        User = "trev";
        IdentityFile = "/home/trev/.ssh/id_ed25519";
        ProxyJump = "gateway";
      };
      "game" = {
        HostName = "10.10.10.111";
        User = "trev";
        IdentityFile = "/home/trev/.ssh/id_ed25519";
        ProxyJump = "gateway";
      };
      "mail" = {
        HostName = "10.10.10.112";
        User = "trev";
        IdentityFile = "/home/trev/.ssh/id_ed25519";
        ProxyJump = "gateway";
      };
      "media" = {
        HostName = "10.10.10.107";
        User = "trev";
        IdentityFile = "/home/trev/.ssh/id_ed25519";
        ProxyJump = "gateway";
      };
      "monitor" = {
        HostName = "10.10.10.109";
        User = "trev";
        IdentityFile = "/home/trev/.ssh/id_ed25519";
        ProxyJump = "gateway";
      };
      "nixaws" = {
        HostName = "localhost";
        Port = 2222;
        User = "root";
        StrictHostKeyChecking = "no";
        UserKnownHostsFile = "/dev/null";
        CheckHostIP = "no";
      };
    };
  };
}
