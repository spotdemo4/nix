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
  };

  config =
    let
      nixos-rebuild = pkgs.nixos-rebuild.override { nix = config.nix.package.out; };

      updater = pkgs.writeShellApplication {
        name = "update";

        runtimeInputs = [
          pkgs.sudo
          pkgs.git
          pkgs.openssh
          pkgs.libnotify
          config.nix.package
          nixos-rebuild
        ];

        text = builtins.readFile (
          pkgs.replaceVars ./update.sh {
            hostname = cfg.hostname;
            user = cfg.user;
          }
        );
      };
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = [ updater ];

      systemd.services.update = {
        description = "Update nixos in the background";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "exec";
          Restart = "on-failure";
          ExecStart = [
            "${updater}/bin/update -w"
          ];
        };
      };
    };
}
