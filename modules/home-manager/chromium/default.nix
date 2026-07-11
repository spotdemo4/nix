{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.trev.programs.chromium.enable = lib.mkEnableOption "Trev's Chromium configuration";

  config = lib.mkIf config.trev.programs.chromium.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.chromium;
      extensions = [
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # UBlock Origin Lite
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # Sponsorblock
        { id = "clngdbkpkpeebahjckkjfobafhncgmne"; } # Stylus
      ];
    };

    catppuccin.chromium = {
      enable = true;
      flavor = "mocha";
    };
  };
}
