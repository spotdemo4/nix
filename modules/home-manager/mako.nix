{ ... }:

{
  services.mako = {
    enable = true;
    defaultTimeout = 5000;
    borderRadius = 10;
    catppuccin = {
      enable = true;
      flavor = "mocha";
    };
  };
}
