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
      image = "ghcr.io/kereis/traefik-certs-dumper:1.8.17@sha256:c64ab91963ea51bcaf251b53d1ddffe329361d162c16cae9ec3016d7fc64d74f";
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
