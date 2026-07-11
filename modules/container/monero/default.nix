{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.monerod;
  inherit (config.virtualisation.quadlet) networks;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.monerod = {
    enable = mkEnableOption "the Monero daemon container";

    image = containerOptions.mkImageOption "ghcr.io/sethforprivacy/simple-monerod:v0.18.5.1@sha256:086eeb95174223ed166915d9f93dcfe4a7699efb89a30ca1569153dbf4f65f02";

    dataDir = mkOption {
      type = types.str;
      default = "/mnt/monero";
      description = "Host directory containing the Monero blockchain data.";
    };

    domain = mkOption {
      type = types.str;
      default = "xmr.trev.kiwi";
      description = "Public domain routed to the restricted RPC endpoint.";
    };

    p2pPort = mkOption {
      type = types.port;
      default = 18080;
      description = "Monero peer-to-peer port.";
    };

    zmqPort = mkOption {
      type = types.port;
      default = 18084;
      description = "Monero ZMQ publisher port.";
    };

    rpcPort = mkOption {
      type = types.port;
      default = 18089;
      description = "Restricted RPC and metrics port.";
    };

    networkName = mkOption {
      type = types.str;
      default = "monero";
      description = "Quadlet network shared with P2Pool.";
    };

    traefikNetworkName = mkOption {
      type = types.str;
      default = "traefik";
      description = "Quadlet network shared with Traefik.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.monerod.containerConfig = {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${cfg.dataDir}:/home/monero"
        ];
        networks = [
          networks.${cfg.networkName}.ref
          networks.${cfg.traefikNetworkName}.ref
        ];
        publishPorts = [
          "${toString cfg.p2pPort}:${toString cfg.p2pPort}"
          "${toString cfg.zmqPort}:${toString cfg.zmqPort}"
          "${toString cfg.rpcPort}:${toString cfg.rpcPort}"
        ];
        exec = [
          "--rpc-restricted-bind-ip=0.0.0.0"
          "--rpc-restricted-bind-port=${toString cfg.rpcPort}"
          "--public-node"
          "--no-igd"
          "--enforce-dns-checkpointing"
          "--enable-dns-blocklist"
          "--prune-blockchain"
          "--zmq-pub=tcp://0.0.0.0:${toString cfg.zmqPort}"
          "--in-peers=50"
          "--out-peers=50"
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http = {
              services.monero.loadbalancer.server.port = cfg.rpcPort;
              routers.monero = {
                rule = "Host(`${cfg.domain}`)";
                service = "monero";
                middlewares = "cors@file";
              };
            };
          };
        };
      };

      networks = {
        ${cfg.networkName} = { };
        ${cfg.traefikNetworkName} = { };
      };
    };
  };
}
