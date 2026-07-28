{ config, lib, ... }:
let
  projects = config.trev.projects;
  settings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
    ssh_connections = [
      {
        host = projects.sshHost;
        nickname = projects.sshHost;
        projects = map (project: { paths = [ project.path ]; }) projects.entries;
      }
    ];
  };
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
