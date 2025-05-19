#!/usr/bin/env bash

if [[ -z "$1" ]]; then
  echo "Error: Please specify a hostname (desktop, server, etc)"
  exit 1
fi

nix-shell -I nixpkgs=channel:nixos-unstable -p git --run "git clone https://github.com/spotdemo4/nix.git /etc/nixos"
nixos-rebuild switch --flake "/etc/nixos#${1}" --accept-flake-config

echo "set root password:"
passwd

echo "set user password:"
passwd trev