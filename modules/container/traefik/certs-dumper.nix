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
      image = "ghcr.io/kereis/traefik-certs-dumper:1.8.20@sha256:c9477262e74924a48e10f71178cbd73c1b0274207464ac11f6e34eb42ed99f4e";
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
