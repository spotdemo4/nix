{pkgs, ...}: let
  configFile = builtins.toFile "config.xml" (builtins.toXML {
    Config = {
      BindAddress = "*";
      Port = 7878;
      SslPort = 9898;
      EnableSsl = false;
      LaunchBrowser = true;
      ApiKey = "8d2672daea5241c5afbfeecf4df41cee";
      AuthenticationMethod = "External";
      AuthenticationRequired = "Enabled";
      Branch = "master";
      LogLevel = "debug";
      SslCertPath = "";
      SslCertPassword = "";
      UrlBase = "";
      InstanceName = "Radarr";
      UpdateMechanism = "Docker";
    };
  });

  utils = import ./utils.nix;
in {
  inherit (utils.mkVolume "radarr_data");

  virtualisation.oci-containers.containers = {
    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      pull = "newer";
      environment = {
        PUID = "1000";
        GUID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${configFile}:/config/config.xml"
        "/mnt/pool/movies:/movies"
        "radarr_data:/config"
      ];
      ports = [
        "7878:7878"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.radarr.rule" = "Host(`radarr.trev.zip`)";
        "traefik.http.routers.radarr.entryPoints" = "https";
        "traefik.http.routers.radarr.tls" = "true";
        "traefik.http.routers.radarr.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.radarr.middlewares" = "authelia@docker";
      };
    };
  };
}
