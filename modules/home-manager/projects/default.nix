{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = config.trev.projects;
  forgejo = owner: repo: "https://trev.zip/${owner}/${repo}";
  github = repo: "https://github.com/spotdemo4/${repo}";
  hyprctl = lib.getExe' config.wayland.windowManager.hyprland.package "hyprctl";
  hyprlauncher = lib.getExe config.services.hyprlauncher.package;
  awk = lib.getExe pkgs.gawk;
  notify-send = lib.getExe pkgs.libnotify;
  ssh = lib.getExe' pkgs.openssh "ssh";
  zed = lib.getExe config.programs.zed-editor.package;

  openProject =
    project:
    let
      localPath = "${cfg.localRoot}/${project.name}";
      browserCommand = lib.escapeShellArgs [
        (lib.getExe config.programs.chromium.package)
        "--new-window"
        project.url
      ];
      luaExpression =
        target:
        let
          editorCommand = lib.escapeShellArgs [
            zed
            "--new"
            target
          ];
        in
        lib.escapeShellArg "open_project(${builtins.toJSON editorCommand}, ${builtins.toJSON browserCommand})";
      remoteLabel = host: "Remote (${host})";
      # SSH sessions start in the home directory, so a "~/" path works relative to it.
      remoteTest = "test -d ${lib.escapeShellArg (lib.removePrefix "~/" project.path)}";
    in
    pkgs.writeShellApplication {
      name = "open-project-${lib.replaceStrings [ "/" ] [ "-" ] project.name}";
      text = ''
        # Prints the address SSH connects to first for an alias: the jump host when the alias
        # uses ProxyJump, otherwise its own HostName. Aliases may not exist in DNS.
        first_hop() {
          local config jump
          config=$(${ssh} -G "$1" 2>/dev/null)
          jump=$(${awk} '$1 == "proxyjump" { print $2 }' <<<"$config")
          if [ -n "$jump" ] && [ "$jump" != none ]; then
            jump=''${jump%%,*} # first jump of a chain
            jump=''${jump#*@}  # drop user@
            jump=''${jump%:*}  # drop :port
            config=$(${ssh} -G "$jump" 2>/dev/null)
          fi
          ${awk} '$1 == "hostname" { print $2 }' <<<"$config"
        }

        # A quick ping first avoids waiting for SSH to time out when the host is offline.
        host_has_project() {
          ping -c 1 -W 1 "$(first_hop "$1")" >/dev/null 2>&1 \
            && ${ssh} -n -o BatchMode=yes -o ConnectTimeout=3 "$1" ${lib.escapeShellArg remoteTest} 2>/dev/null
        }

        # Check every host in parallel, then collect them in the configured order.
        hosts=(${lib.escapeShellArgs cfg.sshHosts})
        pids=()
        for host in "''${hosts[@]}"; do
          host_has_project "$host" &
          pids+=("$!")
        done

        choices=()
        if [ -d ${lib.escapeShellArg localPath} ]; then
          choices+=(Local)
        fi
        for i in "''${!hosts[@]}"; do
          if wait "''${pids[$i]}"; then
            choices+=("Remote (''${hosts[$i]})")
          fi
        done

        case "''${#choices[@]}" in
          0)
            ${notify-send} ${lib.escapeShellArg "Can't open ${project.name}"} \
              ${lib.escapeShellArg "It isn't checked out locally or on any reachable SSH host."}
            exit 1
            ;;
          1) choice=''${choices[0]} ;;
          *) choice=$(printf '%s\n' "''${choices[@]}" | ${hyprlauncher} --dmenu) ;;
        esac

        case "$choice" in
          Local) exec ${hyprctl} eval ${luaExpression localPath} ;;
          ${lib.concatMapStringsSep "\n  " (
            host:
            "${lib.escapeShellArg (remoteLabel host)}) exec ${hyprctl} eval ${luaExpression "ssh://${host}:${project.path}"} ;;"
          ) cfg.sshHosts}
          *) exit 0 ;;
        esac
      '';
    };
in
{
  options.trev.projects = {
    sshHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = lib.filter (host: host != osConfig.networking.hostName) [
        "dev"
        "desktop"
      ];
      defaultText = lib.literalExpression ''
        lib.filter (host: host != osConfig.networking.hostName) [ "dev" "desktop" ]
      '';
      description = ''
        SSH hosts containing the development projects, in the order they are offered. A host is
        only offered when it (or its ProxyJump host) answers a ping and contains the project.
      '';
    };

    localRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/dev";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/dev"'';
      description = "Local directory checked for project checkouts";
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
              description = "Project path on the SSH hosts";
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
          name = "discord-embedder";
          path = "~/dev/discord-embedder";
          url = forgejo "llc" "discord-embedder";
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
          name = "glquic";
          path = "~/dev/glquic";
          url = forgejo "llc" "glquic";
        }
        {
          name = "nix";
          path = "~/dev/nix";
          url = github "nix";
        }
        {
          name = "nix-fix-hash";
          path = "~/dev/nix-fix-hash";
          url = forgejo "llc" "nix-fix-hash";
        }
        {
          name = "nix-init";
          path = "~/dev/nix-init";
          url = forgejo "llc" "nix-init";
        }
        {
          name = "nix-shield";
          path = "~/dev/nix-shield";
          url = forgejo "llc" "nix-shield";
        }
        {
          name = "nixaws";
          path = "~/dev/nixaws";
          url = forgejo "llc" "nixaws";
        }
        {
          name = "osxsdk";
          path = "~/dev/osxsdk";
          url = forgejo "llc" "osxsdk";
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
          name = "pi-action";
          path = "~/dev/pi-action";
          url = forgejo "llc" "pi-action";
        }
        {
          name = "pr-tracker";
          path = "~/dev/pr-tracker";
          url = forgejo "llc" "pr-tracker";
        }
        {
          name = "QuantaTrack";
          path = "~/dev/QuantaTrack";
          url = forgejo "quanta" "QuantaTrack";
        }
        {
          name = "runner-images";
          path = "~/dev/runner-images";
          url = forgejo "llc" "runner-images";
        }
        {
          name = "shellHook";
          path = "~/dev/shellHook";
          url = forgejo "llc" "shellHook";
        }
        {
          name = "solid-toast";
          path = "~/dev/solid-toast";
          url = forgejo "llc" "solid-toast";
        }
        {
          name = "template/cpp";
          path = "~/dev/template/cpp";
          url = forgejo "template" "cpp";
        }
        {
          name = "template/gleam";
          path = "~/dev/template/gleam";
          url = forgejo "template" "gleam";
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
          name = "template/stack";
          path = "~/dev/template/stack";
          url = forgejo "template" "stack";
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
          name = "trev-proxy";
          path = "~/dev/trev-proxy";
          url = forgejo "llc" "trev-proxy";
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
          name = "TrevDesk";
          path = "~/dev/TrevDesk";
          url = forgejo "llc" "TrevDesk";
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
          genericName = "Zed and Chromium project";
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
