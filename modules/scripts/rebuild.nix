{ pkgs, ... }:
 
{
  environment.systemPackages = with pkgs; [
    (writeShellApplication {
      name = "rebuild";

      runtimeInputs = with pkgs; [ git ];

      text = ''
        if [ -z "$1" ]; then
          echo "Usage: rebuild <host name>"
          exit 1
        fi

        pushd /etc/nixos

        echo "Getting most recent good flake.lock..."
        sudo git fetch
        sudo git checkout origin/main -- flake.lock

        echo "NixOS Rebuilding..."
        sudo git add .
        sudo nixos-rebuild switch --flake "/etc/nixos#$1"

        echo "Waiting for network..."
        until ping -c1 www.google.com >/dev/null 2>&1; do :; done

        echo "Committing and pushing..."
        gen=$(nixos-rebuild list-generations | grep current)
        sudo git commit -m "$gen"
        sudo git push -u origin main

        popd
      '';
    })
  ];
}