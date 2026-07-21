{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks;
in
{
  imports = [
    (self + /modules/container/monero)
    (self + /modules/container/p2pool)
    (self + /modules/container/portainer)
    (self + /modules/container/tor)
    (self + /modules/container/traefik)
    (self + /modules/container/traefik-certs-dumper)
    (self + /modules/container/valkey)
  ];

  virtualisation.quadlet = {
    secrets = {
      "cloudflare-dns".file = self + /secrets/cloudflare-dns.age;
      "crowdsec".file = self + /secrets/crowdsec.age;
      "cloudflare-turnstile-site-key".file = self + /secrets/cloudflare-turnstile-site-key.age;
      "cloudflare-turnstile-secret-key".file = self + /secrets/cloudflare-turnstile-secret-key.age;
      "user-admin".file = self + /secrets/user-admin.age;
      "user-trev".file = self + /secrets/user-trev.age;
    };
  };

  trev.containers = {
    monerod = {
      enable = true;
      dataDir = "/mnt/monero";
      domain = "xmr.trev.kiwi";
      p2pPort = 18080;
      zmqPort = 18084;
      rpcPort = 18089;
    };

    p2pool = {
      enable = true;
      wallet = "48cRLf4fjuQVjzBg2JmAhzCL3QyakZ84tRr6aWKWaLVRHjszar566X8bUEbdZ8hgRC8N8ES69V8RqGJQjpVrK94XUs93Mtw";
      stratumPort = 3333;
      p2pPort = 37889;
      monerodZmqPort = 18084;
      monerodRpcPort = 18089;
    };

    portainer = {
      enable = true;
      podmanSocket = "/run/podman/podman.sock";
      routerRule = "HostRegexp(`portainer.trev.(zip|kiwi)`)";
      servicePort = 9000;
    };

    tor = {
      enable = true;
      nickname = "trevrelay";
      contactInfo = "tor AT trev DOT kiwi";
      bandwidthRate = "20 MBytes";
      orPort = 9090;
      metricsPort = 9091;
      metricsHostIP = "10.10.10.105";
      metricsAllowedIP = "10.10.10.109";
    };

    traefik = {
      enable = true;
      podmanSocket = "/run/podman/podman.sock";
      dashboardDomain = "traefik.trev.xyz";
      acmeEmail = "me@trev.xyz";
      acmeDomains = {
        "trev.kiwi" = [ "*.trev.kiwi" ];
        "trev.rs" = [ "*.trev.rs" ];
        "trev.xyz" = [ "*.trev.xyz" ];
        "trev.zip" = [
          "*.trev.zip"
          "*.s3.trev.zip"
          "*.web.trev.zip"
        ];
        "trev.コム" = [ "*.trev.コム" ];
      };
      tracesEndpoint = "10.10.10.109:4317";
      logsEndpoint = "http://10.10.10.109:9428/insert/opentelemetry/v1/logs";
      crowdsecAddress = "10.10.10.114:6061";
      ports = {
        http = 80;
        https = 443;
        rsync = 873;
        rsyncTls = 874;
        metrics = 8080;
        plex = 32400;
        minecraft = 25565;
        syncthing = 22000;
      };
      secrets = {
        cloudflareDns = config.virtualisation.quadlet.secrets."cloudflare-dns";
        crowdsec = config.virtualisation.quadlet.secrets."crowdsec";
        turnstileSiteKey = config.virtualisation.quadlet.secrets."cloudflare-turnstile-site-key";
        turnstileSecretKey = config.virtualisation.quadlet.secrets."cloudflare-turnstile-secret-key";
        userAdmin = config.virtualisation.quadlet.secrets."user-admin";
        userTrev = config.virtualisation.quadlet.secrets."user-trev";
      };
    };

    traefik-certs-dumper = {
      enable = true;
      outputDir = "/mnt/certs";
    };

    valkey = {
      enable = true;
      instances.traefik = {
        enable = true;
        publishPorts = [ "10.10.10.105:6379:6379" ];
        networks = [ networks.traefik.ref ];
        args = [ "--notify-keyspace-events Ksg" ];
      };
    };
  };
}
