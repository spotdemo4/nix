{...}: {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;

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
