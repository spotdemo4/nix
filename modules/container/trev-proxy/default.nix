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
  ) (byProtocol "http" ++ byProtocol "tls");

  upstream = route: "${route.address}:${toString route.port}";
  listen = route: "${cfg.listenAddress}:${toString route.listen}";
  common = route: {
    proxy_protocol = route.proxyProtocol;
  };

  # An http or tls route takes one certificate, so split its domains by certificate.
  certificateRoutes =
    hostsKey: extra: route:
    let
      groups = groupBy certificateFor route.domains;
    in
    mapAttrsToList (
      certificate: domains:
      common route
      // extra route
      // {
        name = if length (attrNames groups) == 1 then route.name else "${route.name}-${certificate}";
        listen = listen route;
        ${hostsKey} = domains;
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
  httpRoutes = certificateRoutes "hosts" (route: {
    inherit (route) http3;
    upstream_protocol = route.upstreamProtocol;
    forwarded_headers = route.forwardedHeaders;
    request_headers = route.requestHeaders;
  });
  tlsRoutes = certificateRoutes "sni" (_: { });

  plainRoute =
    route:
    common route
    // {
      inherit (route) name;
      listen = listen route;
      upstream = upstream route;
    };

  byProtocol = protocol: builtins.filter (route: route.protocol == protocol) routes;

  # Stalwart keeps certificates in its database, so a renewal must be pushed to it.
  stalwartPush = pkgs.writeShellApplication {
    name = "stalwart-certificate-push";
    runtimeInputs = [
      pkgs.jq
      pkgs.stalwart-cli
    ];
    text = ''
      domain="$1"
      STALWART_URL=${lib.escapeShellArg cfg.certificatesExport.stalwart.url}
      STALWART_TOKEN="$(< "$2")"
      export STALWART_URL STALWART_TOKEN

      ids="$(stalwart-cli query Certificate --json --fields subjectAlternativeNames |
        jq -r --arg domain "$domain" \
          'select(.subjectAlternativeNames | if type == "object" then keys else . end | index($domain)) | .id')"
      if [ -z "$ids" ]; then
        echo "no Stalwart certificate covers $domain" >&2
        exit 1
      fi

      for id in $ids; do
        jq -n --rawfile cert fullchain.pem --rawfile key key.pem \
          '{certificate: {"@type": "Text", value: $cert}, privateKey: {"@type": "Text", secret: $key}}' |
          stalwart-cli update Certificate "$id" --stdin
      done
      stalwart-cli create Action --json '{"@type": "ReloadTlsCertificates"}'
    '';
  };

  configFile = (pkgs.formats.toml { }).generate "trev-proxy.toml" (
    {
      http = concatLists (map httpRoutes (byProtocol "http"));
      tls = concatLists (map tlsRoutes (byProtocol "tls"));
      tcp = map plainRoute (byProtocol "tcp");
      udp = map plainRoute (byProtocol "udp");
    }
    // optionalAttrs (cfg.otlpEndpoint != null) {
      telemetry.otlp_endpoint = cfg.otlpEndpoint;
    }
  );
in
{
  options.trev.containers.trev-proxy = {
    enable = mkEnableOption "the trev-proxy container";

    image = mkImageOption "trev.zip/llc/trev-proxy:0.4.1@sha256:b06ede35f509b85840e0ee49ae790979f14858d984ae60a4a9560de5f9586eef";

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address trev-proxy listens on.";
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

      stalwart = {
        url = mkOption {
          type = types.str;
          default = "https://mail.trev.xyz";
          description = "Stalwart endpoint that renewed certificates are pushed to.";
        };
        apiKeySecret = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Name of the agenix secret containing a Stalwart API key that can query and update certificates and reload TLS.";
        };
        certificates = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Certificates replacing the Stalwart certificate covering the same domain after each renewal.";
        };
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
      {
        assertion =
          cfg.certificatesExport.stalwart.certificates == [ ]
          || cfg.certificatesExport.stalwart.apiKeySecret != null;
        message = "trev-proxy needs certificatesExport.stalwart.apiKeySecret to push certificates to Stalwart";
      }
    ]
    ++ map (certificate: {
      assertion = cfg.certificates ? ${certificate};
      message = "trev-proxy cannot push unknown certificate ${certificate} to Stalwart";
    }) cfg.certificatesExport.stalwart.certificates
    ++ map (route: {
      assertion = route.address != null;
      message = "trev.proxy.routes.${route.name} on ${route.host} needs an address";
    }) routes
    ++ map (route: {
      assertion =
        route.auth == null
        || (route.protocol == "http" || route.protocol == "tls") && cfg.auth.groups ? ${route.auth};
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
        # The apex and wildcard share one TXT name, so a resolver can cache it with
        # only one of the values past lego's timeout. Let's Encrypt only asks the
        # authoritative servers, which lego still waits for.
        extraLegoFlags = [ "--dns.propagation.disable-rns" ];
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
          ''
          + lib.optionalString (builtins.elem domain cfg.certificatesExport.stalwart.certificates) ''
            ${lib.getExe stalwartPush} ${lib.escapeShellArg domain} ${
              config.age.secrets.${cfg.certificatesExport.stalwart.apiKeySecret}.path
            }
          '';
      }) cfg.certificates;
    };

    virtualisation.quadlet.containers.trev-proxy.containerConfig = {
      image = cfg.image;
      pull = "missing";
      # Host networking lets reloads bind new listeners without republishing ports.
      networks = [ "host" ];
      volumes = [
        "${configDir}:${configDir}:ro"
        "${acmeDir}:${acmeDir}:ro"
      ];
      exec = [ "${configDir}/config.toml" ];
      stopTimeout = 35;
    };

    # The registry may sit behind this proxy, so it is unreachable once the
    # switch stops the old container. Pull while the old one still serves it.
    system.preSwitchChecks.trev-proxy-image = ''
      if [ "$2" != dry-activate ]; then
        ${lib.getExe config.virtualisation.podman.package} pull --policy missing --quiet ${lib.escapeShellArg cfg.image}
      fi
    '';
  };
}
