{
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes networks;
in
{
  virtualisation.quadlet = {
    containers.p2pool.containerConfig = {
      image = "ghcr.io/sethforprivacy/p2pool:v4.14@sha256:e17c486221fe4a62cd884ce8a0ddbc29a2ec9d6b3a93bd846a5c87243a26d6a3";
      pull = "missing";
      volumes = [
        "${volumes."p2pool".ref}:/home/p2pool"
      ];
      networks = [
        networks."monero".ref
      ];
      publishPorts = [
        "3333:3333" # stratum
        "37889:37889" # p2p
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
    };

    volumes = {
      p2pool = { };
    };
  };
}
