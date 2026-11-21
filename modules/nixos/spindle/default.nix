{
  config,
  inputs,
  lib,
  pkgs,
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
  cfg = config.trev.spindle;
  tangled = inputs.tangled.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.tangled.nixosModules.spindle ];

  options.trev.spindle = {
    enable = mkEnableOption "the Tangled spindle CI runner";

    domain = mkOption {
      type = types.str;
      default = "spindle.trev.zip";
      description = "Public hostname of the spindle; it is also the spindle's identity, did:web:<domain>, so keep it.";
    };

    owner = mkOption {
      type = types.str;
      description = "DID of the spindle's owner, who it runs CI for while admission is closed.";
    };

    port = mkOption {
      type = types.port;
      default = 6555;
      description = "Port the spindle's HTTP server listens on, which trev-proxy routes the domain to.";
    };

    keyFile = mkOption {
      type = types.path;
      default = self + /secrets/spindle-key.age;
      description = "agenix file holding the spindle's EC P-256 signing key in PEM, which its did:web document publishes.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.spindle = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
    };

    age.secrets.spindle-key.file = cfg.keyFile;

    services.tangled.spindle = {
      enable = true;
      server = {
        hostname = cfg.domain;
        inherit (cfg) owner;
        listenAddr = "0.0.0.0:${toString cfg.port}";
      };
      keyPath = config.age.secrets.spindle-key.path;
      contact.email = "me@trev.xyz";
      # Keep logs on disk instead of in Tangled's S3 bucket.
      artifactStores.s3.bucket = "";
      cache = {
        backend = "disk";
        diskDir = "/var/lib/spindle/cache";
        maxBytes = 20 * 1000 * 1000 * 1000;
      };
      pipelines = {
        # The default of 5m is too short for most Nix builds.
        workflowTimeout = "1h";
        # Leave room for the GitHub and Forgejo runners on this host.
        microvm.limits.total = {
          vcpus = 8;
          memoryMiB = 16 * 1024;
        };
        # Guests read from these instead of cache.nixos.org alone.
        nixCache = {
          readUrls = [
            "https://nix.trev.zip"
            "https://cache.nixos.org"
          ];
          trustedPublicKeys = [
            "trev:I39N/EsnHkvfmsbx8RUW+ia5dOzojTQNCTzKYij1chU="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];
        };
      };
    };

    systemd.tmpfiles.rules = [
      "L+ /var/lib/spindle/images/nixos - - - - ${tangled.spindle-nixos-image}"
    ];
  };
}
