{
  pkgs,
  ...
}: {
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
    ];
  };

  catppuccin.zed = {
    enable = true;
    accent = "sky";
    flavor = "mocha";
  };
}
