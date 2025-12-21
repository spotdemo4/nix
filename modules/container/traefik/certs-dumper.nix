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
      image = "ghcr.io/kereis/traefik-certs-dumper:1.8.18@sha256:d21e8931b8f1dd9a2c875e51327e5bfbec4db57d9c9223e7b9c3cf831be64aad";
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
