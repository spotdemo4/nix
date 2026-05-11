{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "git-firefly"
      "gleam"
      "html"
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
    extraPackages = with pkgs; [
      nixd
      nil
      claude-code
    ];
    mutableUserSettings = false;
    userSettings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
      agent_servers = {
        claude-acp = {
          type = "registry";
          env.CLAUDE_CODE_EXECUTABLE = "${pkgs.claude-code}/bin/claude";
        };
        codex-acp = {
          type = "registry";
        };
      };
    };
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
}
