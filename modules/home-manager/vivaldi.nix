{ lib, config, pkgs, ... }:
 
{
  options.vivaldi-conf = {
    enable = lib.mkEnableOption "enable vivaldi config";
  };

  config = lib.mkIf config.vivaldi-conf.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.vivaldi;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # UBlock Origin
        { id = "bkkmolkhemgaeaeggcmfbghljjjoofoh"; } # Catppuccin Chrome Theme
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # Sponsorblock
        { id = "clngdbkpkpeebahjckkjfobafhncgmne"; } # Stylus
      ];
    };
  };
}
