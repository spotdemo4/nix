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
  imports = [
    ./p2pool.nix
  ];

  virtualisation.quadlet = {
    containers.monerod.containerConfig = {
      image = "ghcr.io/sethforprivacy/simple-monerod:v0.18.4.5@sha256:3760d68b2825174e3db504cbea06e9dd06262a2e4593fb13940da3f9ddaa0685";
      pull = "missing";
      volumes = [
        "/mnt/monero:/home/monero"
      ];
      networks = [
        networks."monero".ref
        networks."traefik".ref
      ];
      publishPorts = [
        "18080:18080" # p2p
        "18084:18084" # zmq
        "18089:18089" # rpc for metrics
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
        attrs.traefik = {
          enable = true;
          http = {
            services.monero.loadbalancer.server.port = 18089;
            routers.monero = {
              rule = "Host(`xmr.trev.kiwi`)";
              service = "monero";
              middlewares = "cors@file";
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
