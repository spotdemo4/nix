{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks;
  inherit (config) secrets;
in
{
  secrets = {
    "radarr".file = self + /secrets/radarr.age;
    "sonarr".file = self + /secrets/sonarr.age;
  };

  virtualisation.quadlet = {
    containers.unpackerr.containerConfig = {
      image = "ghcr.io/unpackerr/unpackerr:0.15.2@sha256:89e13608521ece21dd300c39229fd595a55fbf4b8152771af5670a7455b5c747";
      pull = "missing";
      user = "1000:1000";
      secrets = [
        "${secrets."radarr".env},target=UN_RADARR_0_API_KEY"
        "${secrets."sonarr".env},target=UN_SONARR_0_API_KEY"
      ];
      environments = {
        TZ = "America/Detroit";
        UN_RADARR_0_URL = "http://radarr:7878";
        UN_SONARR_0_URL = "http://sonarr:8989";
      };
      volumes = [
        "/mnt/pool:/pool"
      ];
      networks = [
        networks."radarr".ref
        networks."sonarr".ref
      ];
    };
  };
}
