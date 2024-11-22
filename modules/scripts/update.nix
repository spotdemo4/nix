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

        printf "\033[0;36mChecking for changes in remote...\n\033[0m"
        sudo git fetch
        LOCAL=$(sudo git rev-parse @)
        REMOTE=$(sudo git rev-parse "@{u}")
        BASE=$(sudo git merge-base @ "@{u}")
        if [ "$LOCAL" = "$REMOTE" ]; then
          echo "Up-to-date."
        elif [ "$LOCAL" = "$BASE" ]; then
          echo "Need to pull. Aborting..."
          exit 1
        elif [ "$REMOTE" = "$BASE" ]; then
          echo "Good to push."
        else
          echo "Diverged. Aborting..."
          exit 1
        fi

        printf "\033[0;36mUpdating...\n\033[0m"
        sudo nix flake update

        printf "\033[0;36mStopping tailscale...\n\033[0m"
        sudo systemctl stop tailscaled

        printf "\033[0;36mRebuilding...\n\033[0m"
        sudo git add .
        sudo nixos-rebuild switch --flake "/etc/nixos#$1"

        printf "\033[0;36mWaiting for network...\n\033[0m"
        until ping -c1 www.google.com >/dev/null 2>&1; do :; done

        printf "\033[0;36mCommitting and pushing...\n\033[0m"
        gen=$(nixos-rebuild list-generations | grep current)
        sudo git commit -m "$gen"
        sudo git push -u origin main

        printf "\033[0;36mStarting tailscale...\n\033[0m"
        sudo systemctl start tailscaled

        popd
      '';
    })
  ];
}