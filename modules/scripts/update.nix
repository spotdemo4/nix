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

        text = pkgs.replaceVars ./update.sh {
          user = "${config.update.user}";
        };
      })
    ];
  };
}
