{
  config,
  lib,
  pkgs,
  ...
}:
let
  mcpServers = lib.mapAttrs (
    _name: server:
    {
      command = server.command;
    }
    // lib.optionalAttrs (server.args != [ ]) {
      args = server.args;
    }
    // lib.optionalAttrs (server ? env && server.env != { }) {
      env = server.env;
    }
  ) config.programs.mcp.servers;
in
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
    mutableUserSettings = false;
    mutableUserKeymaps = false;
    userSettings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
      context_servers = mcpServers;
    };
    userKeymaps = builtins.fromJSON (builtins.readFile ./keymap.json);
    enableMcpIntegration = false;
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
