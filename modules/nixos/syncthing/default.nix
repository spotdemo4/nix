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
          id = "6Y5HP4G-VVTITOU-AXUS3T7-NCM33QB-3GRVWVE-PKD6BEG-NS5L2HV-X4FDGA2";
          name = "server";
        };
      };
      folders = {
        "codex" = {
          id = "7g6xq-7j2k4";
          devices = [ "server" ];
          label = "codex";
          path = "/home/trev/.codex";
          ignorePatterns = [
            "!auth.json"
            "**"
          ];
        };
      };
    };
  };
}
