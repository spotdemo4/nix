{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "gleam"
      "html"
      "nix"
      "proto"
      "ruff"
      "sql"
      "svelte"
      "toml"
      "zig"
    ];
    extraPackages = with pkgs; [
      nixd
      nil
      claude-code
    ];
    mutableUserSettings = false;
    userSettings = pkgs.lib.attrsets.updateManyAttrsByPath [
      {
        path = [
          "agent_servers"
          "claude-acp"
          "env"
          "CLAUDE_CODE_EXECUTABLE"
        ];
        update = _: "${pkgs.claude-code}/bin/claude";
      }
    ] builtins.fromJSON (builtins.readFile ./settings.json);
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
