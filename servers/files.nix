{ self, ... }:
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ map (x: self + /modules/container/${x}.nix) [
    "portainer-agent"
    "traefik-kop"
  ]
  ++ map (x: self + /modules/container/${x}) [
    "attic"
    "monerod"
    "copyparty"
  ];

  # Traefik mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.113";
  };
}
