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

        text = builtins.readFile (pkgs.replaceVars ./../../scripts/update.sh {
          hostname = "${config.update.hostname}";
          user = "${config.update.user}";
        });
      })
    ];
  };
}
