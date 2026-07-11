{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  options.trev.programs.zen.enable = lib.mkEnableOption "Trev's Zen Browser configuration";

  config = lib.mkIf config.trev.programs.zen.enable {
    programs.zen-browser = {
      enable = true;
      policies = {
        DisableAppUpdate = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        OfferToSaveLogins = false;
      };
      profiles.default = {
        name = "default";
        isDefault = true;
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          bitwarden
          kagi-search
          sponsorblock
          stylus
          ublock-origin
        ];
        userChrome = builtins.readFile "${pkgs.trev.catppuccin-zen-browser}/Mocha/Sky/userChrome.css";
        userContent = builtins.readFile "${pkgs.trev.catppuccin-zen-browser}/Mocha/Sky/userContent.css";
      };
    };
  };
}
