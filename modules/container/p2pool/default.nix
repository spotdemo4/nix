{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes networks;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.p2pool.containerConfig = {
      image = "ghcr.io/sethforprivacy/p2pool:v4.12@sha256:856c48acc99369e880d833bb4b3d1a0a866179dc85f2ee941a039767b257b425";
      pull = "missing";
      volumes = [
        "${volumes."p2pool".ref}:/home/p2pool"
      ];
      networks = [
        networks."traefik".ref
      ];
      exec = [
        "--wallet"
        "48cRLf4fjuQVjzBg2JmAhzCL3QyakZ84tRr6aWKWaLVRHjszar566X8bUEbdZ8hgRC8N8ES69V8RqGJQjpVrK94XUs93Mtw"
        "--stratum"
        "0.0.0.0:3333"
        "--p2p"
        "0.0.0.0:37889"
        "--host"
        "monerod"
        "--zmq-port"
        "18084"
        "--rpc-port"
        "18089"
        "--loglevel"
        "0"
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            tcp = {
              services = {
                p2pool-stratum.loadbalancer.server.port = 3333;
                p2pool-p2p.loadbalancer.server.port = 37889;
              };
              routers = {
                p2pool-stratum = {
                  rule = "HostSNI(`*`)";
                  entryPoints = "p2pool-stratum";
                  service = "p2pool-stratum";
                };
                p2pool-p2p = {
                  rule = "HostSNI(`*`)";
                  entryPoints = "p2pool-p2p";
                  service = "p2pool-p2p";
                };
              };
            };
          };
        };
      };
    };

    volumes = {
      p2pool = { };
    };
  };
}
