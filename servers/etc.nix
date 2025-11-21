{ self, ... }:
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ map (x: self + /modules/container/${x}.nix) [
    # Containers to import
    "portainer-agent"
    "traefik-kop"
  ]
  ++ map (x: self + /modules/container/${x}) [
    "monerod"
    "p2pool"
  ];

  # Traefik mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.114";
  };
}
