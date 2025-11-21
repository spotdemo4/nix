{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "svelte"
      "nix"
      "sql"
    ];
    extraPackages = with pkgs; [
      nixd
      nil
      alejandra
    ];
    userSettings = {
      buffer_font_family = "Fira Code";
      languages = {
        "Nix" = {
          formatter = {
            external = {
              command = "alejandra";
              arguments = [
                "--quiet"
                "--"
              ];
            };
          };
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
  };
}
