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

        printf "\033[0;36mChecking for changes in remote...\n\033[0m"
        sudo git fetch
        if [ -z "$(sudo git diff HEAD origin/main)" ]; then
          echo "No remote changes found."
        else
          echo "Changes in remote found. Checking for local changes..."
          if [ -z "$(sudo git status --porcelain --untracked-files=no)" ]; then
            echo "Local changes found, please merge local & remote. Aborting update."
            exit 1
          else
            echo "No local changes found. Pulling from remote..."
            sudo git pull origin main
          fi
        fi

        printf "\033[0;36mDeleting old generations...\n\033[0m"
        sudo nix-collect-garbage --delete-older-than 7d

        printf "\033[0;36mGetting most recent flake.lock...\n\033[0m"
        sudo git checkout origin/main -- flake.lock

        printf "\033[0;36mStopping tailscale...\n\033[0m"
        sudo systemctl stop tailscaled

        printf "\033[0;36mRebuilding...\n\033[0m"
        sudo git add .
        sudo nixos-rebuild switch --flake "/etc/nixos#$1"

        printf "\033[0;36mWaiting for network...\n\033[0m"
        until ping -c1 www.google.com >/dev/null 2>&1; do :; done

        printf "\033[0;36mCommitting and pushing...\n\033[0m"
        sudo git commit -m "$(nixos-rebuild list-generations | grep current)"
        sudo git push -u origin main

        printf "\033[0;36mStarting tailscale...\n\033[0m"
        sudo systemctl start tailscaled

        popd
      '';
    })
  ];
}