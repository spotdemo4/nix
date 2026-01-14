{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  programs.zen-browser = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
    };
    profiles.default = {
      name = "default";
      isDefault = true;
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
        stylus
        sponsorblock
      ];
      userChrome = builtins.readFile "${pkgs.trev.catppuccin-zen-browser}/Mocha/Sky/userChrome.css";
      userContent = builtins.readFile "${pkgs.trev.catppuccin-zen-browser}/Mocha/Sky/userContent.css";
    };
  };
}
