{...}: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
  };

  catppuccin.ghostty = {
    enable = true;
    flavor = "mocha";
  };
}
