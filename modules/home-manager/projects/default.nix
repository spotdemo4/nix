{ config, lib, ... }:
let
  cfg = config.trev.projects;
in
{
  options.trev.projects = {
    sshHost = lib.mkOption {
      type = lib.types.str;
      default = "dev";
      description = "SSH host containing the development projects";
    };

    entries = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Project name shown in application launchers";
            };
            path = lib.mkOption {
              type = lib.types.str;
              description = "Project path on the SSH host";
            };
          };
        }
      );
      default = [
        {
          name = "astal";
          path = "~/dev/astal";
        }
        {
          name = "bumper";
          path = "~/dev/bumper";
        }
        {
          name = "codex-action";
          path = "~/dev/codex-action";
        }
        {
          name = "codex-commit";
          path = "~/dev/codex-commit";
        }
        {
          name = "DuckMetrics";
          path = "~/dev/DuckMetrics";
        }
        {
          name = "flake-release";
          path = "~/dev/flake-release";
        }
        {
          name = "nix";
          path = "~/dev/nix";
        }
        {
          name = "nix-fix-hash";
          path = "~/dev/nix-fix-hash";
        }
        {
          name = "nix-init";
          path = "~/dev/nix-init";
        }
        {
          name = "nixaws";
          path = "~/dev/nixaws";
        }
        {
          name = "oxc-zed";
          path = "~/dev/oxc-zed";
        }
        {
          name = "pangram-chrome";
          path = "~/dev/pangram-chrome";
        }
        {
          name = "rsync-action";
          path = "~/dev/rsync-action";
        }
        {
          name = "serialization-bench";
          path = "~/dev/serialization-bench";
        }
        {
          name = "stack";
          path = "~/dev/stack";
        }
        {
          name = "template/cpp";
          path = "~/dev/template/cpp";
        }
        {
          name = "template/go";
          path = "~/dev/template/go";
        }
        {
          name = "template/kotlin";
          path = "~/dev/template/kotlin";
        }
        {
          name = "template/node";
          path = "~/dev/template/node";
        }
        {
          name = "template/python";
          path = "~/dev/template/python";
        }
        {
          name = "template/rust";
          path = "~/dev/template/rust";
        }
        {
          name = "template/zig";
          path = "~/dev/template/zig";
        }
        {
          name = "trev-mono";
          path = "~/dev/trev-mono";
        }
        {
          name = "trevbar";
          path = "~/dev/trevbar";
        }
        {
          name = "trevpkgs";
          path = "~/dev/trevpkgs";
        }
        {
          name = "TrevRPC";
          path = "~/dev/TrevRPC";
        }
      ];
      description = "Development projects available through Zed";
    };
  };

  config = lib.mkIf config.trev.programs.zed.enable {
    xdg.desktopEntries = builtins.listToAttrs (
      map (project: {
        name = "zed-${lib.replaceStrings [ "/" ] [ "-" ] project.name}";
        value = {
          name = "Zed: ${project.name}";
          genericName = "Zed remote project";
          exec = ''${lib.getExe config.programs.zed-editor.package} "ssh://${cfg.sshHost}:${project.path}"'';
          icon = "zed";
          terminal = false;
          categories = [
            "Development"
            "IDE"
          ];
        };
      }) cfg.entries
    );
  };
}
