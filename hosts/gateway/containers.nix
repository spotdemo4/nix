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
    (self + /modules/container/wireguard)
  ];

  virtualisation.quadlet = {
    secrets = {
      "wireguard-server".file = self + /secrets/wireguard-server.age;
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

    wireguard = {
      enable = true;
      serverConfigSecret = config.virtualisation.quadlet.secrets."wireguard-server";
    };
  };
}
