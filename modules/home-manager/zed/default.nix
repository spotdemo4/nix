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
    userSettings = builtins.fromJSON (
      builtins.replaceStrings [ "@claude_bin@" ] [ "${pkgs.claude-code}/bin/claude" ] (
        builtins.readFile ./settings.json
      )
    );
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
