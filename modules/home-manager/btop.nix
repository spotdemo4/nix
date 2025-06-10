{...}: {
  programs.btop = {
    enable = true;
  };

  home.shellAliases = {
    top = "btop";
  };

  catppuccin.btop = {
    enable = true;
    flavor = "mocha";
  };
}
