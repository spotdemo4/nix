{ ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "html"
      "nix"
      "sql"
      "svelte"
      "toml"
    ];
    mutableUserSettings = false;
    userSettings = builtins.fromJSON (builtins.readFile ./settings.json);
  };

  # Zed Theme
  catppuccin.zed = {
    enable = true;
    accent = "sky";
    flavor = "mocha";
    italics = false;
  };
}
