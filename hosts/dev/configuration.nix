{ self, ... }:
{
  imports = [
    (self + /modules/nixos/profiles/homelab-lxc.nix)
    (self + /modules/nixos/profiles/development.nix)
    (self + /modules/nixos/profiles/mcp-secrets.nix)
  ];

  home-manager.users.trev.imports = [
    (self + /modules/home-manager/profiles/trev/remote-development.nix)
  ];
}
