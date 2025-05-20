{
  config,
  self,
  pkgs,
  ...
}: let
  configFile = (pkgs.formats.yaml {}).generate "pve.yml" {
    default = {
      user = "readonly@pve";
      token_name = "prometheus";
      token_value = "ca4427ad-a179-440d-894c-46ede39e95a8";
      verify_ssl = false;
    };
  };
in {
  virtualisation.oci-containers.containers = {
    pve-exporter = {
      image = "ghcr.io/prometheus-pve/prometheus-pve-exporter:latest";
      pull = "newer";
      volumes = [
        "${configFile}:/etc/prometheus/pve.yml"
      ];
      networks = [
        "prometheus"
      ];
    };
  };
}
