{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "trev" = {
        HostName = "://trev.xyz";
        User = "trev";
        IdentityFile = "~/.ssh/id_ed25519";
      };
      "build" = {
        HostName = "10.10.10.108";
        User = "trev";
        IdentityFile = "~/.ssh/id_ed25519";
        ProxyJump = "trev";
      };
    };
  };
}
