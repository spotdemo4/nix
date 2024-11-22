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
        CHANGES=$(sudo git diff HEAD origin/main)
        if [ -z "$CHANGES" ]; then
          echo "No changes found."
        else
          echo "Changes found, aborting."
          exit 1
        fi

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