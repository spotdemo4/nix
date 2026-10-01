{
  config,
  hostname,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.trev.proxy;
  lan = import (self + /lib/lan);

  # Transparent routes to this host, whose replies must go back through the gateway.
  transparentRoutes = builtins.filter (
    route: route.transparent && route.address == lan.addresses.${hostname} or null
  ) (builtins.attrValues cfg.routes);
  markRules = lib.concatMapStrings (route: ''
    iifname "${cfg.interface}" ${
      if route.protocol == "udp" then "udp" else "tcp"
    } dport ${toString route.port} ct state new ct mark set 0x7470
  '') transparentRoutes;

  route = types.submodule (
    { config, ... }:
    {
      options = {
        protocol = mkOption {
          type = types.enum [
            "tls"
            "tcp"
            "udp"
          ];
          default = "tls";
          description = "Protocol trev-proxy uses for this route; tls terminates TLS and routes by SNI.";
        };

        domains = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "SNI hostnames matched by a tls route.";
        };

        listen = mkOption {
          type = types.port;
          default = if config.protocol == "tls" then 443 else config.port;
          defaultText = lib.literalMD "443 for tls routes, otherwise `port`";
          description = "Port trev-proxy listens on for this route.";
        };

        address = mkOption {
          type = types.nullOr types.str;
          default = lan.addresses.${hostname} or null;
          defaultText = lib.literalMD "the host's LAN address";
          description = "Upstream address.";
        };

        port = mkOption {
          type = types.port;
          description = "Upstream port.";
        };

        auth = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Device group whose client certificates may use this tls route; null allows anyone.";
        };

        proxyProtocol = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to send a PROXY protocol v2 header to the upstream.";
        };

        transparent = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to connect to the upstream from the client's own address.";
        };
      };
    }
  );
in
{
  options.trev.proxy = {
    routes = mkOption {
      type = types.attrsOf route;
      default = { };
      description = "Routes this host exposes through trev-proxy on the gateway.";
    };

    interface = mkOption {
      type = types.str;
      default = "eth0";
      description = "Interface that connects this host to the gateway.";
    };
  };

  config = {
    assertions = lib.mapAttrsToList (name: route: {
      assertion = route.protocol == "tls" -> route.domains != [ ];
      message = "trev.proxy.routes.${name} is a tls route and needs at least one domain";
    }) cfg.routes;

    # Transparent connections come from the client's address, so mark them and
    # route their replies back through the gateway instead of the default route.
    systemd.services.trev-proxy-upstream = lib.mkIf (transparentRoutes != [ ]) {
      description = "Policy routing for replies to trev-proxy transparent routes";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = with pkgs; [
        iproute2
        nftables
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        nft -f - <<'EOF'
        table inet trev-proxy
        delete table inet trev-proxy
        table inet trev-proxy {
          chain prerouting {
            type filter hook prerouting priority mangle;
            ${markRules}
            ct direction reply ct mark 0x7470 meta mark set 0x7470
          }
        }
        EOF
        ip rule del fwmark 0x7470 lookup 7470 2>/dev/null || true
        ip rule add fwmark 0x7470 lookup 7470
        ip route replace default via ${lan.addresses.gateway} dev ${cfg.interface} table 7470
      '';
      preStop = ''
        nft delete table inet trev-proxy || true
        ip rule del fwmark 0x7470 lookup 7470 || true
        ip route flush table 7470 || true
      '';
    };
  };
}
