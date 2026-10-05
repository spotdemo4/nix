{
  config,
  hostname,
  lib,
  self,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.trev.proxy;
  lan = import (self + /lib/lan);

  route = types.submodule (
    { config, ... }:
    {
      options = {
        protocol = mkOption {
          type = types.enum [
            "http"
            "tls"
            "tcp"
            "udp"
          ];
          default = "http";
          description = "Protocol trev-proxy uses for this route; http terminates TLS and HTTP and routes each request by host, tls terminates TLS and routes by SNI.";
        };

        domains = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Hostnames matched by an http or tls route.";
        };

        listen = mkOption {
          type = types.port;
          default = if config.protocol == "http" || config.protocol == "tls" then 443 else config.port;
          defaultText = lib.literalMD "443 for http and tls routes, otherwise `port`";
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
          description = "Device group whose client certificates may use this http or tls route; null allows anyone.";
        };

        http3 = mkOption {
          type = types.bool;
          default = config.protocol == "http" && config.auth == null;
          defaultText = lib.literalMD "whether this is an http route without `auth`";
          description = "Whether an http route also serves HTTP/3; browsers don't send client certificates over it.";
        };

        upstreamProtocol = mkOption {
          type = types.enum [
            "http/1.1"
            "h2c"
          ];
          default = "http/1.1";
          description = "What an http route forwards requests over; h2c upstreams must also accept HTTP/1.1 on the same port for WebSockets.";
        };

        forwardedHeaders = mkOption {
          type = types.listOf (
            types.enum [
              "x-forwarded-for"
              "x-forwarded-proto"
              "x-forwarded-host"
              "x-real-ip"
              "forwarded"
            ]
          );
          default = [
            "x-forwarded-for"
            "x-forwarded-proto"
            "x-forwarded-host"
          ];
          description = "Headers an http route sets to tell the upstream about the client, replacing any the client sent.";
        };

        requestHeaders = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Headers an http route sets on every request to the upstream; an empty value removes the header.";
        };

        proxyProtocol = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to send a PROXY protocol v2 header to the upstream.";
        };
      };
    }
  );
in
{
  options.trev.proxy.routes = mkOption {
    type = types.attrsOf route;
    default = { };
    description = "Routes this host exposes through trev-proxy on the gateway.";
  };

  config.assertions = lib.concatLists (
    lib.mapAttrsToList (name: route: [
      {
        assertion = route.protocol == "http" || route.protocol == "tls" -> route.domains != [ ];
        message = "trev.proxy.routes.${name} needs at least one domain as a ${route.protocol} route";
      }
      {
        assertion = route.http3 -> route.protocol == "http" && route.auth == null;
        message = "trev.proxy.routes.${name} can only serve HTTP/3 as an http route without auth";
      }
      {
        assertion = route.upstreamProtocol == "h2c" -> route.protocol == "http";
        message = "trev.proxy.routes.${name} can only use an h2c upstream as an http route";
      }
    ]) cfg.routes
  );
}
