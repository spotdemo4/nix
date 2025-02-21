{ pkgs, ... }:
 
{
  environment.systemPackages = with pkgs; [
    (writeShellApplication {
      name = "update";

      runtimeInputs = with pkgs; [
        git
        libnotify
      ];

      text = ''
        USER=trev
        USER_ID=1000

        function notify() {
          sudo -u $USER DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus notify-send "$@"
        }

        HOST=$1
        if [ -z "$HOST" ]; then
          echo "Usage: update <host name> (-d)"
          exit 1
        fi

        shift

        DELETE=false
        while getopts 'd' flag; do
          case "$flag" in
            d) DELETE=true ;;
            *) echo "Invalid flag: $flag" ;;
          esac
        done

        pushd /etc/nixos

        notify --urgency=normal "Updater" "Starting update."
        printf "\033[0;36mChecking for remote changes...\n\033[0m"
        sudo git fetch
        if [ -z "$(sudo git diff HEAD origin/main)" ]; then
          echo "No remote changes found."
        else
          echo "Changes in remote found. Checking for local changes..."
          if [ -z "$(sudo git status --porcelain --untracked-files=no)" ]; then
            notify --urgency=normal "Updater" "Pulling update from remote..."
            echo "No local changes found. Pulling from remote..."
            sudo git pull origin main
          else
            notify --urgency=critical "Updater" "Aborted rebuild due to diverged branches."
            echo "Local changes found, please merge local & remote. Aborting update."
            exit 1
          fi
        fi

        printf "\033[0;36mUpdating...\n\033[0m"
        sudo nix flake update

        printf "\033[0;36mStopping tailscale...\n\033[0m"
        sudo systemctl stop tailscaled

        printf "\033[0;36mRebuilding...\n\033[0m"
        sudo git add .
        sudo nixos-rebuild switch --flake "/etc/nixos#$HOST"

        printf "\033[0;36mWaiting for network...\n\033[0m"
        until ping -c1 www.google.com >/dev/null 2>&1; do :; done

        printf "\033[0;36mCommitting and pushing...\n\033[0m"
        sudo git commit -m "$(nixos-rebuild list-generations | grep current)"
        sudo git push -u origin main

        printf "\033[0;36mStarting tailscale...\n\033[0m"
        sudo systemctl start tailscaled

        if [ "$DELETE" = true ] ; then
          printf "\033[0;36mDeleting old generations...\n\033[0m"
          sudo nix-collect-garbage --delete-older-than 7d
        fi

        notify --urgency=normal "Updater" "Finished update."

        popd
      '';
    })
  ];
}