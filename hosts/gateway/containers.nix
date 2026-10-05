{
  config,
  self,
  ...
}:
{
  imports = [
    (self + /modules/container/monero)
    (self + /modules/container/p2pool)
    (self + /modules/container/portainer)
    (self + /modules/container/tor)
    (self + /modules/container/trev-proxy)
    (self + /modules/container/wireguard)
  ];

  age.secrets.cloudflare-dns.file = self + /secrets/cloudflare-dns.age;
  age.secrets.stalwart-certificates.file = self + /secrets/stalwart-certificates.age;

  virtualisation.quadlet = {
    secrets = {
      "wireguard-server".file = self + /secrets/wireguard-server.age;
    };
  };

  # Routes to upstreams outside this flake's hosts.
  trev.proxy.routes = {
    windows = {
      domains = [ "windows.trev.xyz" ];
      address = "10.10.10.104";
      port = 8085;
      auth = "admin";
    };
    windows-udp = {
      protocol = "udp";
      address = "10.10.10.104";
      port = 8085;
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

    trev-proxy = {
      enable = true;
      acmeEmail = "me@trev.xyz";
      certificates = {
        "trev.kiwi" = [ "*.trev.kiwi" ];
        "trev.rs" = [ "*.trev.rs" ];
        "trev.xyz" = [ "*.trev.xyz" ];
        "trev.zip" = [
          "*.trev.zip"
          "*.s3.trev.zip"
          "*.web.trev.zip"
        ];
        # trev.コム
        "trev.xn--tckwe" = [ "*.trev.xn--tckwe" ];
      };
      cloudflareDnsSecret = "cloudflare-dns";
      certificatesExport = {
        directory = "/mnt/certs";
        stalwart = {
          apiKeySecret = "stalwart-certificates";
          certificates = [
            "trev.kiwi"
            "trev.xyz"
            "trev.zip"
          ];
        };
      };
      otlpEndpoint = "http://10.10.10.109:4318";
      auth = {
        ca = ./devices-ca.pem;
        crl = ./devices.crl;
        # Device certificate common names allowed into each group.
        groups =
          let
            devices = [
              "desktop"
              "dev"
              "htpc"
              "laptop"
            ];
          in
          {
            trev = devices;
            admin = devices;
          };
      };
    };

    wireguard = {
      enable = true;
      serverConfigSecret = config.virtualisation.quadlet.secrets."wireguard-server";
    };
  };
}
