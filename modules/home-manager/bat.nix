{...}: {
  programs.bat.enable = true;

  home.shellAliases = {
    cat = "bat";
  };

  catppuccin.bat = {
    enable = true;
    flavor = "mocha";
  };
}
