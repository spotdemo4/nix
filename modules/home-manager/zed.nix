{
  pkgs,
  inputs,
  ...
}: {
  programs.zed-editor = {
    enable = true;
    extensions = [
      "svelte"
      "nix"
      "sql"
    ];
  };

  catppuccin.zed = {
    enable = true;
    accent = "sky";
    flavor = "mocha";
  };
}
