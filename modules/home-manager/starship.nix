{pkgs, ...}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  catppuccin.starship = {
    enable = true;
    flavor = "mocha";
  };
}
