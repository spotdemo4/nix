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
      image = "ghcr.io/kereis/traefik-certs-dumper:1.8.21@sha256:de77fe83f31e74fc2910083813c7d2418eedaebdbfb8a0b90df285721d253421";
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
