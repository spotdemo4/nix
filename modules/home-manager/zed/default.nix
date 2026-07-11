{ config, lib, ... }:
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
      userKeymaps = builtins.fromJSON (builtins.readFile ./keymap.json);
      userTasks = builtins.fromJSON (builtins.readFile ./tasks.json);
      enableMcpIntegration = false;
    };

    xdg.configFile."zed/settings.json".source = lib.mkForce ./settings.json;

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
