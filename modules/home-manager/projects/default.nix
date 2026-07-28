{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.trev.projects;
  forgejo = owner: repo: "https://trev.zip/${owner}/${repo}";
  github = repo: "https://github.com/spotdemo4/${repo}";
  hyprctl = lib.getExe' config.wayland.windowManager.hyprland.package "hyprctl";
  openProject =
    project:
    let
      editorCommand = lib.escapeShellArgs [
        (lib.getExe config.programs.zed-editor.package)
        "--new"
        "ssh://${cfg.sshHost}:${project.path}"
      ];
      browserCommand = lib.escapeShellArgs [
        (lib.getExe pkgs.trev.helium)
        "--new-window"
        project.url
      ];
      luaExpression = "open_project(${builtins.toJSON editorCommand}, ${builtins.toJSON browserCommand})";
    in
    pkgs.writeShellApplication {
      name = "open-project-${lib.replaceStrings [ "/" ] [ "-" ] project.name}";
      text = ''
        exec ${hyprctl} eval ${lib.escapeShellArg luaExpression}
      '';
    };
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
            url = lib.mkOption {
              type = lib.types.str;
              description = "Project repository URL";
            };
          };
        }
      );
      default = [
        {
          name = "astal";
          path = "~/dev/astal";
          url = github "astal";
        }
        {
          name = "bumper";
          path = "~/dev/bumper";
          url = forgejo "llc" "bumper";
        }
        {
          name = "codex-action";
          path = "~/dev/codex-action";
          url = forgejo "llc" "codex-action";
        }
        {
          name = "codex-commit";
          path = "~/dev/codex-commit";
          url = forgejo "llc" "codex-commit";
        }
        {
          name = "DuckMetrics";
          path = "~/dev/DuckMetrics";
          url = forgejo "llc" "DuckMetrics";
        }
        {
          name = "flake-release";
          path = "~/dev/flake-release";
          url = forgejo "llc" "flake-release";
        }
        {
          name = "nix";
          path = "~/dev/nix";
          url = github "nix";
        }
        {
          name = "nix-fix-hash";
          path = "~/dev/nix-fix-hash";
          url = github "nix-fix-hash";
        }
        {
          name = "nix-init";
          path = "~/dev/nix-init";
          url = github "nix-init";
        }
        {
          name = "nixaws";
          path = "~/dev/nixaws";
          url = forgejo "llc" "nixaws";
        }
        {
          name = "oxc-zed";
          path = "~/dev/oxc-zed";
          url = github "oxc-zed";
        }
        {
          name = "pangram-chrome";
          path = "~/dev/pangram-chrome";
          url = github "pangram-chrome";
        }
        {
          name = "rsync-action";
          path = "~/dev/rsync-action";
          url = forgejo "llc" "rsync-action";
        }
        {
          name = "serialization-bench";
          path = "~/dev/serialization-bench";
          url = forgejo "llc" "serialization-bench";
        }
        {
          name = "stack";
          path = "~/dev/stack";
          url = forgejo "llc" "stack";
        }
        {
          name = "template/cpp";
          path = "~/dev/template/cpp";
          url = forgejo "template" "cpp";
        }
        {
          name = "template/go";
          path = "~/dev/template/go";
          url = forgejo "template" "go";
        }
        {
          name = "template/kotlin";
          path = "~/dev/template/kotlin";
          url = forgejo "template" "kotlin";
        }
        {
          name = "template/node";
          path = "~/dev/template/node";
          url = forgejo "template" "node";
        }
        {
          name = "template/python";
          path = "~/dev/template/python";
          url = forgejo "template" "python";
        }
        {
          name = "template/rust";
          path = "~/dev/template/rust";
          url = forgejo "template" "rust";
        }
        {
          name = "template/zig";
          path = "~/dev/template/zig";
          url = forgejo "template" "zig";
        }
        {
          name = "trev-mono";
          path = "~/dev/trev-mono";
          url = forgejo "llc" "trev-mono";
        }
        {
          name = "trevbar";
          path = "~/dev/trevbar";
          url = forgejo "llc" "trevbar";
        }
        {
          name = "trevpkgs";
          path = "~/dev/trevpkgs";
          url = github "trevpkgs";
        }
        {
          name = "TrevRPC";
          path = "~/dev/TrevRPC";
          url = forgejo "llc" "TrevRPC";
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
          genericName = "Zed and Helium project";
          exec = lib.getExe (openProject project);
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
