{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  programs.zen-browser = let
    catppuccin-zen-browser = pkgs.stdenv.mkDerivation {
      name = "catppuccin-zen-browser";
      src = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "zen-browser";
        rev = "0893393f721facb884365a318111c4a7fce96b45";
        sha256 = "sha256-+Nf7TUairZBnhYCFVBqiQW9QodV/xWSOnH6X9o6S7rM=";
      };
      installPhase = ''
        cp -r themes/Mocha/Sky "$out"
      '';
    };
  in {
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
      userChrome = builtins.readFile "${catppuccin-zen-browser}/userChrome.css";
      userContent = builtins.readFile "${catppuccin-zen-browser}/userContent.css";
    };
  };
}
