{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.monerod.containerConfig = {
      image = "ghcr.io/sethforprivacy/simple-monerod:v0.18.4.4@sha256:c03c5145bafecc57024bf922a945cfc6fe3dc70fe2cc4a25e6a7e0d351e659ef";
      pull = "missing";
      volumes = [
        "/mnt/monero:/home/monero"
      ];
      publishPorts = [
        "18080" # p2p
        "18084" # zmq
        "18089" # rpc
      ];
      networks = [
        networks."monero".ref
      ];
      exec = [
        "--rpc-restricted-bind-ip=0.0.0.0"
        "--rpc-restricted-bind-port=18089"
        "--public-node"
        "--no-igd"
        "--enforce-dns-checkpointing"
        "--enable-dns-blocklist"
        "--prune-blockchain"
        "--zmq-pub=tcp://0.0.0.0:18084"
        "--in-peers=50"
        "--out-peers=50"
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            tcp.routers = {
              monero-p2p = {
                rule = "HostSNI(`*`)";
                entryPoints = "monero-p2p";
              };
              monero-zmq = {
                rule = "HostSNI(`*`)";
                entryPoints = "monero-zmq";
              };
              monero-rpc = {
                rule = "HostSNI(`*`)";
                entryPoints = "monero-rpc";
              };
            };
          };
        };
      };
    };

    networks = {
      monero = { };
    };
  };
}
