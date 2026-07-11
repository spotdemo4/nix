{
  config,
  lib,
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
  cfg = config.trev.containers.p2pool;
  monerod = lib.attrByPath [ "trev" "containers" "monerod" ] { enable = false; } config;
  inherit (config.virtualisation.quadlet) networks volumes;
in
{
  options.trev.containers.p2pool = {
    enable = mkEnableOption "the P2Pool container";

    image = containerOptions.mkImageOption "ghcr.io/sethforprivacy/p2pool:v4.17@sha256:b46a062c0169a3d5cb37530799a8846f963a0769dbadae18cb24d02c71ca8091";

    wallet = mkOption {
      type = types.str;
      description = "Monero wallet address receiving P2Pool payouts.";
    };

    monerodHost = mkOption {
      type = types.str;
      default = "monerod";
      description = "Container hostname of the Monero daemon.";
    };

    stratumPort = mkOption {
      type = types.port;
      default = 3333;
      description = "P2Pool stratum port.";
    };

    p2pPort = mkOption {
      type = types.port;
      default = 37889;
      description = "P2Pool peer-to-peer port.";
    };

    monerodZmqPort = mkOption {
      type = types.port;
      default = 18084;
      description = "Monero daemon ZMQ port.";
    };

    monerodRpcPort = mkOption {
      type = types.port;
      default = 18089;
      description = "Monero daemon restricted RPC port.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "p2pool";
      description = "Quadlet volume containing P2Pool state.";
    };

    networkName = mkOption {
      type = types.str;
      default = "monero";
      description = "Quadlet network shared with the Monero daemon.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = monerod.enable;
        message = "trev.containers.p2pool requires trev.containers.monerod.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.p2pool.containerConfig = {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/home/p2pool"
        ];
        networks = [
          networks.${cfg.networkName}.ref
        ];
        publishPorts = [
          "${toString cfg.stratumPort}:${toString cfg.stratumPort}"
          "${toString cfg.p2pPort}:${toString cfg.p2pPort}"
        ];
        exec = [
          "--wallet"
          cfg.wallet
          "--stratum"
          "0.0.0.0:${toString cfg.stratumPort}"
          "--p2p"
          "0.0.0.0:${toString cfg.p2pPort}"
          "--host"
          cfg.monerodHost
          "--zmq-port"
          (toString cfg.monerodZmqPort)
          "--rpc-port"
          (toString cfg.monerodRpcPort)
          "--loglevel"
          "0"
        ];
      };

      volumes.${cfg.volumeName} = { };
      networks.${cfg.networkName} = { };
    };
  };
}
