{...}: {
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-radius = 10;
    };
  };

  catppuccin.mako = {
    enable = true;
    flavor = "mocha";
  };
}
