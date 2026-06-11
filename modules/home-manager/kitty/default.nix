{ ... }:
{
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    settings = {
      auto_reload_config = -1;
    };
  };

  catppuccin.kitty = {
    enable = true;
    flavor = "mocha";
  };
}
