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
      image = "ghcr.io/sethforprivacy/p2pool:v4.13@sha256:07ca9a16af667e6802d1dda37fb6377d3f60b700828ef7a6457454c4efbdf52c";
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
