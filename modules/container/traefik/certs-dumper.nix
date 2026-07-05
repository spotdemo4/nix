{
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers volumes;
in
{
  virtualisation.quadlet.containers.traefik-certs-dumper = {
    containerConfig = {
      image = "ghcr.io/kereis/traefik-certs-dumper:1.8.22@sha256:9d71a7cc50d4b00ac30a27ffc94cca375953cd11ebc722772943823528497996";
      pull = "missing";
      user = "1000";
      group = "1000";
      addCapabilities = [
        "CAP_DAC_OVERRIDE"
      ];
      volumes = [
        "${volumes."acme".ref}:/traefik"
        "/mnt/certs:/output"
      ];
    };

    unitConfig = {
      After = containers."traefik".ref;
      BindsTo = containers."traefik".ref;
      ReloadPropagatedFrom = containers."traefik".ref;
    };
  };
}
