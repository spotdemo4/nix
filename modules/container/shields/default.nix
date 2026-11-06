{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    hasPrefix
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalAttrs
    optionalString
    removePrefix
    replaceStrings
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    secretType
    ;
  inherit (config.virtualisation.quadlet) containers networks;
  cfg = config.trev.containers.shields;

  # Regex for an allowed host, escaped for a CEL string in the Caddyfile;
  # `*.example.com` matches any subdomain of example.com but not example.com.
  hostRegex =
    host:
    let
      escaped = replaceStrings [ "." ] [ "\\\\." ] (removePrefix "*." host);
    in
    if hasPrefix "*." host then "([a-z0-9-]+\\\\.)+${escaped}" else escaped;
  hostPattern = concatMapStringsSep "|" hostRegex cfg.allowedUrlHosts;

  # Shields has no allowlist for the URLs Dynamic, Endpoint and other badges
  # fetch, so Caddy checks the `url` query parameter before Shields sees it.
  caddyfile = pkgs.writeText "Caddyfile" ''
    {
    	admin off
    	auto_https off
    }

    :8080 {
    	# Go drops query pairs it can't parse while Node keeps them, so a
    	# malformed pair could hide a `url` parameter from the check below.
    	@malformed expression `{http.request.uri.query}.matches("[;]|%([^0-9A-Fa-f]|[0-9A-Fa-f][^0-9A-Fa-f]|[0-9A-Fa-f]?$)")`
    	respond @malformed "malformed query" 400

    	@url query url=*
    	handle @url {
    ${
      optionalString (cfg.allowedUrlHosts != [ ]) ''
        		@allowed expression `{query.url}.matches("^https://(${hostPattern})(/|$)")`
        		handle @allowed {
        			# Keep only the checked value in case `url` is repeated.
        			uri query url {query.url}
        			reverse_proxy shields:8080
        		}
      ''
    }		respond "url not allowed" 403
    	}

    	reverse_proxy shields:8080
    }
  '';
in
{
  options.trev.containers.shields = {
    enable = mkEnableOption "Shields.io badge server container";

    image = mkImageOption "docker.io/shieldsio/shields:server-2026-08-21@sha256:4d6e9cca61dcd97240d9887fe050a72eab2cc9469a3db4dfc49f3c308c1f5113";

    filter.image = mkImageOption "docker.io/library/caddy:2.11.9-alpine@sha256:71d41fe4b1ae92a058abc87afe614178b996d8a6b96d0f4c71ae30606e5927e3";

    domain = mkOption {
      type = types.str;
      default = "shields.trev.zip";
      description = "Domain routed to the Shields server.";
    };

    port = mkOption {
      type = types.port;
      default = 8084;
      description = "Shields port published on the host.";
    };

    allowedUrlHosts = mkOption {
      type = types.listOf (types.strMatching "(\\*\\.)?[a-z0-9-]+(\\.[a-z0-9-]+)+");
      default = [
        "trev.zip"
        "nix-shield.trev.zip"
        "github.com"
        "*.githubusercontent.com"
      ];
      description = "Hosts that badges taking a `url` query parameter, such as Dynamic and Endpoint badges, may fetch over HTTPS; `*.example.com` allows every subdomain of example.com, and other subdomains must be listed separately.";
    };

    redirectUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "URL the server root redirects to; null keeps the upstream default.";
    };

    githubTokenSecret = mkOption {
      type = types.nullOr secretType;
      default = null;
      description = "Podman secret containing a GitHub token used to raise the GitHub API rate limit.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.shields = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
    };

    virtualisation.quadlet = {
      secrets = optionalAttrs (cfg.githubTokenSecret != null) {
        ${cfg.githubTokenSecret.ref} = cfg.githubTokenSecret;
      };

      containers = {
        shields.containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          environments = {
            PORT = "8080";
            DYNAMIC_AND_ENDPOINT_BADGES_ENABLED = "true";
          }
          // optionalAttrs (cfg.redirectUrl != null) {
            REDIRECT_URI = cfg.redirectUrl;
          };
          secrets = optional (cfg.githubTokenSecret != null) {
            inherit (cfg.githubTokenSecret) ref;
            type = "env";
            target = "GH_TOKEN";
          };
          networks = [ networks.shields.ref ];
        };

        shields-filter = {
          containerConfig = mkContainer {
            image = cfg.filter.image;
            pull = "missing";
            volumes = [ "${caddyfile}:/etc/caddy/Caddyfile:ro" ];
            networks = [ networks.shields.ref ];
            publishPorts = [ "${toString cfg.port}:8080" ];
          };

          unitConfig = {
            After = containers.shields.ref;
            BindsTo = containers.shields.ref;
          };
        };
      };

      networks.shields = { };
    };
  };
}
