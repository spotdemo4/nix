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
      };
    };

    # Link the theme instead of setting userChrome/userContent: those treat a
    # store path string as CSS text, so they would need the theme read (and
    # built) during evaluation
    home.file =
      let
        cfg = config.programs.zen-browser;
        chrome = "${cfg.profilesPath}/${cfg.profiles.default.path}/chrome";
        theme = "${pkgs.trev.catppuccin-zen-browser}/Mocha/Sky";
      in
      {
        "${chrome}/userChrome.css".source = "${theme}/userChrome.css";
        "${chrome}/userContent.css".source = "${theme}/userContent.css";
      };
  };
}
