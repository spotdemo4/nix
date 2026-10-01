{
  self,
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    any
    attrNames
    concatLists
    concatMap
    concatStringsSep
    findFirst
    groupBy
    hasPrefix
    length
    mapAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    removePrefix
    splitString
    tail
    types
    unique
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkImageOption
    ;
  cfg = config.trev.containers.trev-proxy;

  # The config directory is bind-mounted, not baked into the unit, so route
  # changes reach the running proxy as a file rename and never restart it.
  configDir = "/etc/trev-proxy";
  acmeDir = "/var/lib/acme";

  # Routes declared on every host, this one included.
  routes = concatLists (
    mapAttrsToList (
      host: nixos:
      mapAttrsToList (name: route: route // { inherit host name; }) (
        if host == hostname then config.trev.proxy.routes else nixos.config.trev.proxy.routes
      )
    ) self.nixosConfigurations
  );
  routeNames = map (route: route.name) routes;
  duplicateRouteNames = unique (
    builtins.filter (name: length (builtins.filter (other: other == name) routeNames) > 1) routeNames
  );

  # Whether certificate name `pattern` (possibly a wildcard) covers `name`.
  covers =
    name: pattern:
    pattern == name
    ||
      hasPrefix "*." pattern
      && concatStringsSep "." (tail (splitString "." name)) == removePrefix "*." pattern;
  certificateFor =
    name:
    findFirst (certificate: any (covers name) ([ certificate ] ++ cfg.certificates.${certificate})) "" (
      attrNames cfg.certificates
    );
  uncovered = concatMap (
    route:
    map (domain: "${route.name}: ${domain}") (
      builtins.filter (domain: certificateFor domain == "") route.domains
    )
  ) (byProtocol "tls");

  upstream = route: "${route.address}:${toString route.port}";
  listen = route: "${cfg.listenAddress}:${toString route.listen}";
  common = route: {
    inherit (route) transparent;
    proxy_protocol = route.proxyProtocol;
  };

  # A tls route takes one certificate, so split its domains by certificate.
  tlsRoutes =
    route:
    let
      groups = groupBy certificateFor route.domains;
    in
    mapAttrsToList (
      certificate: domains:
      common route
      // {
        name = if length (attrNames groups) == 1 then route.name else "${route.name}-${certificate}";
        listen = listen route;
        sni = domains;
        upstream = upstream route;
        cert = "${acmeDir}/${certificate}/fullchain.pem";
        key = "${acmeDir}/${certificate}/key.pem";
      }
      // optionalAttrs (route.auth != null) (
        {
          client_ca = "${configDir}/devices-ca.pem";
          client_crl = "${configDir}/devices.crl";
        }
        // optionalAttrs (cfg.auth.groups.${route.auth} or null != null) {
          client_allow = cfg.auth.groups.${route.auth};
        }
      )
    ) groups;

  plainRoute =
    route:
    common route
    // {
      inherit (route) name;
      listen = listen route;
      upstream = upstream route;
    };

  byProtocol = protocol: builtins.filter (route: route.protocol == protocol) routes;

  configFile = (pkgs.formats.toml { }).generate "trev-proxy.toml" (
    {
      tls = concatLists (map tlsRoutes (byProtocol "tls"));
      tcp = map plainRoute (byProtocol "tcp");
      udp = map plainRoute (byProtocol "udp");
    }
    // optionalAttrs (cfg.otlpEndpoint != null) {
      telemetry.otlp_endpoint = cfg.otlpEndpoint;
    }
  );

  transparent = any (route: route.transparent) routes;
in
{
  options.trev.containers.trev-proxy = {
    enable = mkEnableOption "the trev-proxy container";

    image = mkImageOption "trev.zip/llc/trev-proxy:0.3.0@sha256:e848bf1ae3ffdfbd54b0c1f1cab0d302b7f745e6fb8eab8a197c59bc9bfee528";

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address trev-proxy listens on.";
    };

    interface = mkOption {
      type = types.str;
      default = "eth0";
      description = "Interface that replies from transparent upstreams arrive on.";
    };

    otlpEndpoint = mkOption {
      type = types.nullOr types.str;
      default = "http://10.10.10.109:4318";
      description = "OpenTelemetry OTLP/HTTP endpoint for traces and metrics.";
    };

    acmeEmail = mkOption {
      type = types.str;
      default = "me@trev.xyz";
      description = "Email address used for ACME registration.";
    };

    certificates = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = { };
      description = "ACME certificate domains mapped to their subject alternative names.";
    };

    cloudflareDnsSecret = mkOption {
      type = types.str;
      description = "Name of the agenix secret containing the Cloudflare DNS API token.";
    };

    certificatesExport = {
      directory = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Host directory receiving `<domain>/cert.pem` and `<domain>/key.pem` copies for other services.";
      };
      uid = mkOption {
        type = types.int;
        default = 1000;
        description = "UID owning exported certificates.";
      };
      gid = mkOption {
        type = types.int;
        default = 1000;
        description = "GID owning exported certificates.";
      };
    };

    auth = {
      ca = mkOption {
        type = types.path;
        description = "PEM file of the CA certificates that issue device certificates.";
      };
      crl = mkOption {
        type = types.path;
        description = "PEM file of a CRL for every CA in `ca`.";
      };
      groups = mkOption {
        type = types.attrsOf (types.nullOr (types.nonEmptyListOf types.str));
        default = { };
        description = "Device groups routes can require, mapped to the device common names in them; null allows any device.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = duplicateRouteNames == [ ];
        message = "trev.proxy.routes names must be unique across hosts: ${concatStringsSep ", " duplicateRouteNames}";
      }
      {
        assertion = uncovered == [ ];
        message = "trev-proxy has no certificate for: ${concatStringsSep ", " uncovered}";
      }
    ]
    ++ map (route: {
      assertion = route.address != null;
      message = "trev.proxy.routes.${route.name} on ${route.host} needs an address";
    }) routes
    ++ map (route: {
      assertion = route.auth == null || route.protocol == "tls" && cfg.auth.groups ? ${route.auth};
      message = "trev.proxy.routes.${route.name} requires unknown device group ${toString route.auth}";
    }) routes;

    environment.etc =
      mapAttrs
        (_: source: {
          inherit source;
          # Copy rather than symlink, so activation renames the file and the proxy reloads it.
          mode = "0444";
        })
        {
          "trev-proxy/config.toml" = configFile;
          "trev-proxy/devices-ca.pem" = cfg.auth.ca;
          "trev-proxy/devices.crl" = cfg.auth.crl;
        };

    security.acme = {
      acceptTerms = true;
      certs = mapAttrs (domain: sans: {
        email = cfg.acmeEmail;
        extraDomainNames = sans;
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        credentialFiles.CF_DNS_API_TOKEN_FILE = config.age.secrets.${cfg.cloudflareDnsSecret}.path;
        postRun =
          let
            inherit (cfg.certificatesExport) directory uid gid;
            target = lib.escapeShellArg "${directory}/${domain}";
          in
          lib.optionalString (directory != null) ''
            install -d -m 0755 -o ${toString uid} -g ${toString gid} ${target}
            install -m 0644 -o ${toString uid} -g ${toString gid} fullchain.pem ${target}/cert.pem
            install -m 0640 -o ${toString uid} -g ${toString gid} key.pem ${target}/key.pem
          '';
      }) cfg.certificates;
    };

    virtualisation.quadlet.containers.trev-proxy.containerConfig = {
      image = cfg.image;
      pull = "missing";
      # Host networking lets reloads bind new listeners without republishing ports.
      networks = [ "host" ];
      addCapabilities = [ "CAP_NET_ADMIN" ];
      volumes = [
        "${configDir}:${configDir}:ro"
        "${acmeDir}:${acmeDir}:ro"
      ];
      exec = [ "${configDir}/config.toml" ];
      stopTimeout = 35;
    };

    # Deliver replies from transparent upstreams to the proxy's sockets.
    systemd.services.trev-proxy-transparent = mkIf transparent {
      description = "Policy routing for trev-proxy transparent routes";
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
            socket transparent 1 meta mark set 0x7470
          }
        }
        EOF
        for family in -4 -6; do
          ip "$family" rule del fwmark 0x7470 iif ${cfg.interface} lookup 7470 2>/dev/null || true
          ip "$family" rule add fwmark 0x7470 iif ${cfg.interface} lookup 7470
        done
        ip -4 route replace local 0.0.0.0/0 dev lo table 7470
        ip -6 route replace local ::/0 dev lo table 7470
      '';
      preStop = ''
        nft delete table inet trev-proxy || true
        for family in -4 -6; do
          ip "$family" rule del fwmark 0x7470 iif ${cfg.interface} lookup 7470 || true
          ip "$family" route flush table 7470 || true
        done
      '';
    };
  };
}
