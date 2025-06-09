{...}: {
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
  };

  catppuccin.ghostty = {
    enable = true;
    flavor = "mocha";
  };
}
