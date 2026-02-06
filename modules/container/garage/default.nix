{
  config,
  self,
  pkgs,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes;
  inherit (config) secrets;
  toLabel = import (self + /modules/util/label);

  cfg = pkgs.replaceVars ./garage.toml {
    metadata_dir = "/meta";
    data_dir = "/data";
    rpc_secret_file = "/secrets/rpc-secret";
    admin_token_file = "/secrets/admin-token";
    metrics_token_file = "/secrets/metrics-token";
  };
in
{
  secrets = {
    "garage-rpc".file = self + /secrets/garage-rpc.age;
    "garage-admin".file = self + /secrets/garage-admin.age;
    "garage-metrics".file = self + /secrets/garage-metrics.age;
  };

  virtualisation.quadlet = {
    containers."garage".containerConfig = {
      image = "docker.io/dxflrs/garage:v1.3.1@sha256:58e68794286868230708803e50495bfe7d1d1c7b696e0c2dee99b03c524fc960";
      pull = "missing";
      volumes = [
        "${cfg}:/etc/garage.toml"
        "${volumes."garage".ref}:/meta"
        "/mnt/garage:/data"
      ];
      secrets = [
        "${secrets."garage-rpc".mount},target=/secrets/rpc-secret,mode=0400"
        "${secrets."garage-admin".mount},target=/secrets/admin-token,mode=0400"
        "${secrets."garage-metrics".mount},target=/secrets/metrics-token,mode=0400"
      ];
      publishPorts = [
        "3900:3900" # s3
        "3901:3901" # web
        "3902:3902" # admin
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http = {
            middlewares = {
              nix-cache = {
                headers.customrequestheaders."X-Forwarded-Host" = "nix.web.trev.zip";
              };
            };
            routers = {
              garage-s3 = {
                rule = "Host(`s3.trev.zip`) || HostRegexp(`^.+\.s3\.trev\.zip$`)";
                service = "garage-s3";
                middlewares = "secure@file";
              };
              garage-web = {
                rule = "Host(`web.trev.zip`) || HostRegexp(`^.+\.web\.trev\.zip$`)";
                service = "garage-web";
                middlewares = "secure@file";
              };
              garage-admin = {
                rule = "Host(`admin.trev.zip`)";
                service = "garage-admin";
                middlewares = "secure@file";
              };
              nix-cache = {
                rule = "Host(`nix.trev.zip`)";
                service = "garage-web";
                middlewares = "nix-cache@redis";
              };
            };
            services = {
              garage-s3.loadbalancer.server.port = 3900;
              garage-web.loadbalancer.server.port = 3901;
              garage-admin.loadbalancer.server.port = 3902;
            };
          };
        };
      };
    };

    volumes = {
      garage = { };
    };
  };
}
