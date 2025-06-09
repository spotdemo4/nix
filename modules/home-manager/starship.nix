{...}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      container = {
        disabled = true;
      };
    };
  };

  catppuccin.starship = {
    enable = true;
    flavor = "mocha";
  };
}
