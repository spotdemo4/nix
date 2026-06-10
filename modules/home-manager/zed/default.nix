{ pkgs, ... }:
{
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
      "sql"
      "svelte"
      "tombi"
      "toml"
      "tsgo"
      "zig"
    ];
    mutableUserSettings = true;
    mutableUserKeymaps = false;
    userSettings = builtins.fromJSON (builtins.readFile ./settings.json);
    userKeymaps = builtins.fromJSON (builtins.readFile ./keymap.json);
    enableMcpIntegration = true;
  };

  home.packages = with pkgs; [
    claude-code
  ];

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
}
