{ ... }:
{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "trev";
    dataDir = "/home/trev";
    settings = {
      devices = {
        "server" = {
          id = "5M4G6QU-FILKNI4-PL7LSZA-IQPDJMC-ETTQ4YB-53ZXVK6-B4GIXPC-SMBZEQV";
        };
      };
      folders = {
        "codex" = {
          id = "7g6xq-7j2k4";
          devices = [ "server" ];
          label = "codex";
          path = "/home/trev/.codex";
          ignorePatterns = [
            "!/home/trev/.codex/auth.json"
            "**"
          ];
        };
      };
    };
  };
}
