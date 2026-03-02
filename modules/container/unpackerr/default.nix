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
      image = "ghcr.io/unpackerr/unpackerr:0.15.0@sha256:9f4cb99b78d8fe2d55f79c490a715e14a8a28d9868373dad642ca5adc2ac3e91";
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
