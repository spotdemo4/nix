{ ... }:
{
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    settings.auto_reload_config = false;
  };

  catppuccin.kitty = {
    enable = true;
    flavor = "mocha";
  };
}
