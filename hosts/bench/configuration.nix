{ self, ... }:
{
  imports = [
    (self + /modules/nixos/profiles/homelab-lxc.nix)
  ];

  home-manager.users.trev.imports = [
    (self + /modules/home-manager/profiles/trev/server.nix)
  ];
}
