{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.trev.update;

  # hypridle keeps this file in the user's runtime directory while they're idle (see the
  # hypridle home-manager module)
  hypridleCheck = pkgs.writeShellApplication {
    name = "update-idle-check";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.procps
    ];
    text = ''
      uid=$(id -u ${lib.escapeShellArg cfg.user})
      # nothing tracks activity without hypridle, e.g. before the user logs in
      if ! pgrep -x -u "$uid" hypridle > /dev/null; then
        exit 0
      fi
      test -e "/run/user/$uid/idle"
    '';
  };
in
{
  options.trev.update = {
    enable = lib.mkEnableOption "host update script";

    hostname = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      defaultText = lib.literalExpression "config.networking.hostName";
      description = "Hostname passed to nixos-rebuild.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "trev";
      description = "User that owns the NixOS checkout.";
    };

    ntfyUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://ntfy.sh/spotdemo4-nix-main";
      description = "ntfy topic URL that announces new main branch revisions.";
    };

    fallbackInterval = lib.mkOption {
      type = lib.types.str;
      default = "1d";
      description = "Interval between update checks used to recover missed notifications.";
    };

    idle = {
      enable = lib.mkEnableOption "" // {
        description = ''
          Whether automatic updates wait until the host has been idle for
          {option}`trev.update.idle.minutes` before switching. The `update` command
          always updates right away.
        '';
      };

      minutes = lib.mkOption {
        type = lib.types.ints.positive;
        default = 15;
        description = "How long the host has to stay idle before an automatic update switches.";
      };

      check = lib.mkOption {
        type = lib.types.nonEmptyListOf lib.types.str;
        default = [ (lib.getExe hypridleCheck) ];
        defaultText = lib.literalMD "a check that the user is idle according to hypridle, or isn't running it";
        description = "Command, checked every minute, that exits 0 while the host is idle.";
      };
    };

    wrapper = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.literalExpression ''[ "flock" "/run/my-work.lock" ]'';
      description = "Command prefix the switch runs under, e.g. to keep other work off the host while it switches.";
    };
  };

  config =
    let
      nixos-rebuild = pkgs.nixos-rebuild.override { nix = config.nix.package.out; };
      stateDirectory = "/var/lib/trev-update";

      retryFile = "${stateDirectory}/retry";

      switch = pkgs.writeShellApplication {
        name = "update-switch";

        runtimeInputs = [
          pkgs.coreutils
          pkgs.libnotify
          pkgs.util-linux
          nixos-rebuild
        ];

        text =
          lib.replaceStrings
            [ "@hostname@" "@retryFile@" "@user@" ]
            [
              (lib.escapeShellArg cfg.hostname)
              (lib.escapeShellArg retryFile)
              (lib.escapeShellArg cfg.user)
            ]
            (builtins.readFile ./switch.sh);
      };

      updater = pkgs.writeShellApplication {
        name = "update";

        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
          pkgs.openssh
          pkgs.systemd
          pkgs.util-linux
        ];

        text =
          lib.replaceStrings
            [
              "@stateDirectory@"
              "@retryFile@"
              "@waitForIdle@"
              "@idleMinutes@"
              "@idleCheck@"
              "@wrapper@"
              "@switch@"
            ]
            [
              (lib.escapeShellArg stateDirectory)
              (lib.escapeShellArg retryFile)
              (lib.boolToString cfg.idle.enable)
              (toString cfg.idle.minutes)
              (lib.escapeShellArgs cfg.idle.check)
              (lib.escapeShellArgs cfg.wrapper)
              (lib.getExe switch)
            ]
            (builtins.readFile ./update.sh);
      };

      updateListener = pkgs.writeShellApplication {
        name = "update-listener";

        runtimeInputs = [
          pkgs.ntfy-sh
          pkgs.systemd
        ];

        text = lib.replaceStrings [ "@ntfyUrl@" ] [ (lib.escapeShellArg cfg.ntfyUrl) ] (
          builtins.readFile ./update-listener.sh
        );
      };

      updateNow = pkgs.writeShellApplication {
        name = "update";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.systemd
        ];
        text = ''
          since="$(date '+%Y-%m-%d %H:%M:%S.%6N')"
          journalctl --follow --output cat --since "$since" --identifier update &
          journal_pid=$!
          trap 'sleep 1; kill "$journal_pid" 2>/dev/null || true' EXIT

          systemctl start update-now.service
        '';
      };

      updateLogs = pkgs.writeShellApplication {
        name = "update-logs";
        runtimeInputs = [ pkgs.systemd ];
        text = ''
          exec journalctl --boot --pager-end \
            --identifier update \
            --identifier update-listener \
            "$@"
        '';
      };
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = [
        updateNow
        updateLogs
      ];

      systemd.services =
        let
          updateService = description: args: {
            inherit description;
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            restartIfChanged = false;
            serviceConfig = {
              Type = "oneshot";
              StateDirectory = "trev-update";
              ExecStart = "${lib.getExe updater}${args}";
            };
          };
        in
        {
          # started by the fallback timer
          update = updateService "Update NixOS" "";
          # started by the update listener
          "update@" = updateService "Update NixOS to revision %i" " %i";
          # started by the update command
          update-now = updateService "Update NixOS without waiting for the host to be idle" " --now";

          update-listener = {
            description = "Listen for NixOS update notifications";
            wantedBy = [ "multi-user.target" ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            serviceConfig = {
              Type = "exec";
              Restart = "always";
              RestartSec = "10s";
              ExecStart = "${updateListener}/bin/update-listener";
            };
          };
        };

      systemd.timers.update = {
        description = "Fallback NixOS update check";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnUnitInactiveSec = cfg.fallbackInterval;
          RandomizedDelaySec = "1h";
          Persistent = true;
        };
      };
    };
}
