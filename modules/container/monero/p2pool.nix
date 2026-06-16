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
      image = "ghcr.io/sethforprivacy/p2pool:v4.16@sha256:c8cd3f2e4fc4be1f117c9c9bf3a6141b9f40082565323b1a09767f061b84bdc5";
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
