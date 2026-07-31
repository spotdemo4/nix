{
  config,
  lib,
  ...
}:
let
  projects = config.trev.projects;
  claude =
    lib.attrByPath
      [
        "trev"
        "programs"
        "claude"
      ]
      {
        enable = false;
        baseUrl = "https://proxy.trev.xyz";
        haikuModel = "gpt-5.6-luna";
        sonnetModel = "gpt-5.6-terra";
        opusModel = "gpt-5.6-sol";
        model = "gpt-5.6-sol";
      }
      config;
  settings = lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ./settings.json)) (
    {
      ssh_connections = [
        {
          host = projects.sshHost;
          nickname = projects.sshHost;
          projects = map (project: { paths = [ project.path ]; }) projects.entries;
        }
      ];
    }
    // lib.optionalAttrs claude.enable {
      agent_servers.claude-acp = {
        type = "custom";
        command = "${config.home.profileDirectory}/bin/claude-agent-acp";
        args = [ ];
        default_config_options = {
          mode = "bypassPermissions";
          model = claude.model;
          effort = "high";
        };
      };
    }
  );
in
{
  options.trev.programs.zed.enable = lib.mkEnableOption "Trev's Zed configuration";

  config = lib.mkIf config.trev.programs.zed.enable {
    programs.zed-editor = {
      enable = true;
      extensions = [
        "bash"
        "git-firefly"
        "gleam"
        "html"
        "ini"
        "kotlin"
        "log"
        "lua"
        "neocmake"
        "nix"
        "oxc"
        "proto"
        "ruff"
        "scss"
        "sql"
        "svelte"
        "tombi"
        "toml"
        "tsgo"
        "zig"
      ];
      mutableUserSettings = false;
      mutableUserKeymaps = false;
      mutableUserTasks = false;
      userSettings = settings;
      userKeymaps = builtins.fromJSON (builtins.readFile ./keymap.json);
      userTasks = builtins.fromJSON (builtins.readFile ./tasks.json);
      enableMcpIntegration = false;
    };

    # Zed Theme
    catppuccin.zed = {
      enable = true;
      accent = "sky";
      flavor = "mocha";
      italics = false;

      icons = {
        enable = true;
        flavor = "mocha";
      };
    };
  };
}
