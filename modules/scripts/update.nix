{
  lib,
  config,
  pkgs,
  ...
}: {
  options.update = {
    enable = lib.mkEnableOption "enable update script";

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = ''
        The hostname of the client.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "trev";
      description = ''
        The user of the script.
      '';
    };
  };

  config = lib.mkIf config.update.enable {
    environment.systemPackages = with pkgs; [
      (writeShellApplication {
        name = "update";

        runtimeInputs = with pkgs; [
          git
          libnotify
        ];

        text = ''
          USER_ID=$(id -u ${config.update.user})

          function notify() {
            sudo -u ${config.update.user} DISPLAY=:0 "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus" notify-send "$@"
          }

          function gprint() {
            printf "\033[0;36m%s\n\033[0m" "$1"
            notify --urgency=normal "Updater" "$1" || true
          }

          function bprint() {
            printf "\033[0;31m%s\n\033[0m" "$1"
            notify --urgency=critical "Updater" "$1" || true
          }

          DELETE=false
          FLAKE=false
          while getopts 'df' flag; do
            case "$flag" in
              d) DELETE=true ;;
              f) FLAKE=true ;;
              *) echo "Invalid flag: $flag" ;;
            esac
          done

          gprint "Starting update"
          pushd /etc/nixos

          sudo git fetch
          if [ -z "$(sudo git diff HEAD origin/main)" ]; then
            echo "No remote changes found"
          else
            echo "Changes in remote found. Checking for local changes..."
            if [ -z "$(sudo git status --porcelain --untracked-files=no)" ]; then
              gprint "Pulling changes from github..."
              sudo git pull origin main
            else
              bprint "Branches are diverged, aborting update"
              exit 1
            fi
          fi

          if [ "$FLAKE" = true ]; then
            gprint "Updating flake..."
            sudo nix flake update
          fi

          gprint "Rebuilding..."
          sudo git add .
          sudo nixos-rebuild switch --flake "/etc/nixos#${config.update.hostname}"

          printf "\033[0;36mWaiting for network...\n\033[0m"
          until ping -c1 www.google.com >/dev/null 2>&1; do :; done

          if sudo git diff-index --quiet HEAD; then
            echo "No local changes found, not pushing."
          else
            gprint "Pushing to github..."
            sudo git commit -m "$(nixos-rebuild list-generations | grep current)"
            sudo git push -u origin main
          fi

          if [ "$DELETE" = true ]; then
            gprint "Deleting old generations..."
            sudo nix-collect-garbage --delete-older-than 7d
          fi

          gprint "Finished update"
          popd
        '';
      })
    ];
  };
}
