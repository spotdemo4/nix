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
      image = "ghcr.io/sethforprivacy/simple-monerod:v0.18.4.4@sha256:83a4a02065429d99ef30570534dda6358faa03df01d5ebb8cd8f900de79a5c77";
      pull = "missing";
      volumes = [
        "/mnt/monero:/home/monero"
      ];
      publishPorts = [
        "18080:18080" # p2p
        "18084:18084" # zmq
        "18089:18089" # rpc
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
            tcp = {
              services = {
                monero-p2p.loadbalancer.server.port = 18080;
                monero-zmq.loadbalancer.server.port = 18084;
              };
              routers = {
                monero-p2p = {
                  rule = "HostSNI(`*`)";
                  entryPoints = "monero-p2p";
                  service = "monero-p2p";
                };
                monero-zmq = {
                  rule = "HostSNI(`*`)";
                  entryPoints = "monero-zmq";
                  service = "monero-zmq";
                };
              };
            };
            http = {
              services.monero-rpc.loadbalancer.server.port = 18089;
              routers.monero-rpc = {
                rule = "HostRegexp(`xmr.trev.(xyz|zip|kiwi)`)";
                service = "monero-rpc";
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
