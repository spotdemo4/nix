{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    ;
  inherit (config.virtualisation.quadlet) volumes;
  cfg = config.trev.containers.stack;
in
{
  options.trev.containers.stack = {
    enable = mkEnableOption "TrevStack server container";

    image = mkImageOption "trev.zip/template/stack/server:3.3.0@sha256:d75f6da8878bc34d9a9f1ee0a457747224bfbc2371e526ab14e26b8e65eb2217";

    domain = mkOption {
      type = types.str;
      default = "stack.trev.zip";
      description = "Domain routed to the TrevStack server.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "TrevStack TCP and UDP port published on the host.";
    };

    certificateDirectory = mkOption {
      type = types.str;
      default = "/mnt/certs/trev.zip";
      description = "Host directory with the `cert.pem` and `key.pem` covering `domain`, as trev-proxy exports them.";
    };

    certificateGid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID that can read `key.pem` in `certificateDirectory`.";
    };

    trustedProxyCIDRs = mkOption {
      type = types.listOf types.str;
      default = [ "10.10.10.105/32" ];
      description = "Proxy CIDRs that send a PROXY protocol header with every TCP connection and QUIC datagram.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "stack";
      description = "Name of the persistent TrevStack data volume.";
    };
  };

  config = mkIf cfg.enable {
    # TrevStack terminates TLS itself, for QUIC and WebTransport, so the
    # gateway passes TLS and QUIC through and tells it the client's address
    # with PROXY headers, which it requires from trustedProxyCIDRs.
    trev.proxy.routes.stack = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
      passthrough = true;
      http3 = true;
      proxyProtocol = true;
      quicProxyProtocol = true;
    };

    virtualisation.quadlet = {
      containers.stack.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        user = "65532";
        group = "65532";
        addGroups = [ (toString cfg.certificateGid) ];
        # The server advertises HTTP/3 on its own port, so it listens on 443
        # like the gateway; that needs no capability inside its network.
        sysctl."net.ipv4.ip_unprivileged_port_start" = "0";
        # The SQLite database lives under $XDG_CONFIG_HOME/trevstack.
        environments = {
          XDG_CONFIG_HOME = "/data";
          PORT = "443";
          TLS_CERT = "/certs/cert.pem";
          TLS_KEY = "/certs/key.pem";
          TRUSTED_PROXY_CIDRS = concatStringsSep "," cfg.trustedProxyCIDRs;
        };
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/data:U"
          "${cfg.certificateDirectory}:/certs:ro"
        ];
        publishPorts = [
          "${toString cfg.port}:443/tcp"
          "${toString cfg.port}:443/udp"
        ];
      };

      volumes.${cfg.volumeName} = { };
    };

    # The server only reads its certificate at startup. The gateway writes
    # key.pem after cert.pem when it renews them, so a change to key.pem means
    # both are new.
    systemd.paths.stack-certificate = {
      description = "Watch the TrevStack certificate for renewals";
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = "${cfg.certificateDirectory}/key.pem";
    };

    systemd.services.stack-certificate = {
      description = "Restart TrevStack to load its renewed certificate";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe' pkgs.systemd "systemctl"} try-restart stack.service";
      };
    };
  };
}
