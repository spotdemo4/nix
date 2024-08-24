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

        printf "\033[4;36m Getting most recent good flake.lock...\n"
        sudo git fetch
        sudo git checkout origin/main -- flake.lock

        printf "\033[4;36m NixOS Rebuilding...\n"
        sudo git add .
        sudo nixos-rebuild switch --flake "/etc/nixos#$1"

        printf "\033[4;36m Waiting for network...\n"
        until ping -c1 www.google.com >/dev/null 2>&1; do :; done

        printf "\033[4;36m Committing and pushing...\n"
        gen=$(nixos-rebuild list-generations | grep current)
        sudo git commit -m "$gen"
        sudo git push -u origin main

        popd
      '';
    })
  ];
}