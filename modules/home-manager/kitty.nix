{ ... }:
{
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
  };

  catppuccin.kitty = {
    enable = true;
    flavor = "mocha";
  };
}
