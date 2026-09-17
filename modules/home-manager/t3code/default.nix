{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.trev.services.t3code;
in
{
  options.trev.services.t3code = {
    enable = lib.mkEnableOption "T3 Code server";

    package = lib.mkPackageOption pkgs "t3code" { };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address on which the T3 Code server listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3773;
      description = "Port on which the T3 Code server listens.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.t3code = {
      enable = true;
      package = cfg.package;
    };

    systemd.user.services.t3code = {
      Unit = {
        Description = "T3 Code server";
        X-Restart-Triggers = [ cfg.package ];
      };

      Service = {
        Type = "simple";
        WorkingDirectory = config.home.homeDirectory;
        Environment = [ "T3CODE_HOME=${config.home.homeDirectory}/.t3" ];
        ExecStart = "${lib.getExe' cfg.package "t3"} serve --host ${lib.escapeShellArg cfg.host} --port ${toString cfg.port}";
        KillMode = "mixed";
        OOMPolicy = "continue";
        Restart = "always";
        RestartSec = 5;
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
