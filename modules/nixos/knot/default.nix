{
  config,
  inputs,
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
  cfg = config.trev.knot;
  lan = import (self + /lib/lan);
in
{
  imports = [ inputs.tangled.nixosModules.knot-rs ];

  options.trev.knot = {
    enable = mkEnableOption "the Tangled knot git server";

    domain = mkOption {
      type = types.str;
      default = "knot.trev.zip";
      description = "Public hostname of the knot; it is also the knot's identity, did:web:<domain>, so keep it.";
    };

    admins = mkOption {
      type = types.nonEmptyListOf types.str;
      description = "DIDs with admin authority over the knot; the first is its owner.";
    };

    port = mkOption {
      type = types.port;
      default = 5555;
      description = "Port the knot's HTTP server listens on, which trev-proxy routes the domain to.";
    };

    sshPort = mkOption {
      type = types.port;
      default = 2222;
      description = "Port the knot's SSH server listens on, which trev-proxy forwards the gateway's port 22 to.";
    };

    masterKeyFile = mkOption {
      type = types.path;
      default = self + /secrets/knot-master-key.age;
      description = "agenix file holding a `KNOT_MASTER_KEY=<base64>` line, the key that unseals the knot's signing keys.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes = {
      knot = {
        domains = [ cfg.domain ];
        inherit (cfg) port;
      };
      # Tangled builds SSH clone URLs without a port, so the knot needs port 22.
      knot-ssh = {
        protocol = "tcp";
        listen = 22;
        port = cfg.sshPort;
      };
    };

    age.secrets.knot-master-key.file = cfg.masterKeyFile;

    services.tangled.knot-rs = {
      enable = true;
      environmentFile = config.age.secrets.knot-master-key.path;
      settings = {
        server = {
          hostname = cfg.domain;
          inherit (cfg) admins;
          listen_addr = "[::]:${toString cfg.port}";
          ssh_listen_addr = "[::]:${toString cfg.sshPort}";
          # Every SSH connection comes from the gateway, so all clients share this limit.
          ssh_max_inflight_per_peer = 16;
        };
        atproto.plc_directory = "https://plc.directory";
        contact.email = "me@trev.xyz";
        # SHA-256 repositories can't push to or fetch from SHA-1 hosts like GitHub and Forgejo.
        git.object_format = "sha1";
        xrpc = {
          trusted_proxy_header = "x-forwarded-for";
          trusted_proxies = [ lan.addresses.gateway ];
        };
      };
    };
  };
}
