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
      pkgs.replaceVars ./settings.json {
        claude = "${pkgs.claude-code}/bin/claude";
      }
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
