{...}: {
  programs.kitty = {
    enable = true;
    shellIntegration.enableFishIntegration = true;
  };

  catppuccin.kitty = {
    enable = true;
    flavor = "mocha";
  };
}
