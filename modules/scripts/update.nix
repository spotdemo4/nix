{ pkgs, ... }:
 
{
  environment.systemPackages = with pkgs; [
    (writeShellApplication {
      name = "update";

      runtimeInputs = with pkgs; [ git ];

      text = ''
        if [ -z "$1" ]; then
          echo "Usage: update <host name>"
          exit 1
        fi

        pushd /etc/nixos
        echo "NixOS Rebuilding..."
        sudo nix flake update
        
        sudo git add .

        sudo nixos-rebuild switch --flake "/etc/nixos#$1"

        echo "Waiting for network..."
        until ping -c1 www.google.com >/dev/null 2>&1; do :; done

        gen=$(nixos-rebuild list-generations | grep current)
        sudo git commit -m "$gen"
        sudo git push -u origin main

        popd
      '';
    })
  ];
}