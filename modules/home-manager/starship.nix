{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      container = {
        disabled = true;
      };
      command_timeout = 3600000;
    };
  };

  catppuccin.starship = {
    enable = true;
    flavor = "mocha";
  };
}
