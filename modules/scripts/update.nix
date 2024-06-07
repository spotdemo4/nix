{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "update";

  text = ''
    sudo su
    pushd /etc/nixos
    echo "NixOS Rebuilding..."

    nixos-rebuild switch --flake /etc/nixos#default
    gen=$(nixos-rebuild list-generations | grep current)

    git add .
    git commit -m "$gen"
    git push -u origin main

    popd
  '';
}