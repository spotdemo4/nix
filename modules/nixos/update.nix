{
  lib,
  config,
  pkgs,
  self,
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

  config = let
    updater = pkgs.writeShellApplication {
      name = "update";

      runtimeInputs = with pkgs; [
        git
        openssh
        libnotify
      ];

      text = builtins.readFile (pkgs.replaceVars (self + /scripts/update.sh) {
        hostname = "${config.update.hostname}";
        user = "${config.update.user}";
      });
    };
  in
    lib.mkIf config.update.enable {
      environment.systemPackages = [
        updater
      ];

      systemd.services.update = {
        description = "Update nixos in the background";
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "exec";
          Restart = "on-failure";
          ExecStart = [
            "${updater}/bin/update -w -d"
          ];
        };
      };
    };
}
