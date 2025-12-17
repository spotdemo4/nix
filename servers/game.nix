{ self, ... }:
let
  toImports = import self + /modules/util/import;
in
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ toImports "container" [
    "minecraft"
    "portainer-agent"
    "traefik-kop"
  ];

  # Traefik mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.111";
  };
}
