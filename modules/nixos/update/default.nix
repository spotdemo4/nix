{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.trev.update;
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
  };

  config =
    let
      nixos-rebuild = pkgs.nixos-rebuild.override { nix = config.nix.package.out; };
      stateDirectory = "/var/lib/trev-update";

      updater = pkgs.writeShellApplication {
        name = "update";

        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
          pkgs.openssh
          pkgs.libnotify
          pkgs.util-linux
          nixos-rebuild
        ];

        text = builtins.readFile (
          pkgs.replaceVars ./update.sh {
            hostname = cfg.hostname;
            inherit stateDirectory;
            user = cfg.user;
          }
        );
      };

      updateListener = pkgs.writeShellApplication {
        name = "update-listener";

        runtimeInputs = [
          pkgs.ntfy-sh
          pkgs.systemd
        ];

        text = builtins.readFile (
          pkgs.replaceVars ./update-listener.sh {
            ntfyUrl = lib.escapeShellArg cfg.ntfyUrl;
          }
        );
      };
    in
    lib.mkIf cfg.enable {
      systemd.services.update = {
        description = "Update NixOS";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          RestartSec = "5m";
          StateDirectory = "trev-update";
          ExecStart = "${updater}/bin/update";
        };
      };

      systemd.services."update@" = {
        description = "Update NixOS to revision %i";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          RestartSec = "5m";
          StateDirectory = "trev-update";
          ExecStart = "${updater}/bin/update %i";
        };
      };

      systemd.services.update-listener = {
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
