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

        printf "\033[0;36mUpdating...\n\033[0m"
        sudo nix flake update

        printf "\033[0;36mRebuilding...\n\033[0m"
        sudo git add .
        sudo nixos-rebuild switch --flake "/etc/nixos#$1"

        printf "\033[0;36mWaiting for network...\n\033[0m"
        until ping -c1 www.google.com >/dev/null 2>&1; do :; done

        printf "\033[0;36mCommitting and pushing...\n\033[0m"
        gen=$(nixos-rebuild list-generations | grep current)
        sudo git commit -m "$gen"
        sudo git push -u origin main

        popd
      '';
    })
  ];
}