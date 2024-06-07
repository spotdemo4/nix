{ lib, config, pkgs, ... }:
 
{
  options.brave-conf = {
    enable = lib.mkEnableOption "enable brave config";
  };

  config = lib.mkIf config.brave-conf.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # UBlock Origin
        { id = "bkkmolkhemgaeaeggcmfbghljjjoofoh"; } # Catppuccin Chrome Theme
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # Sponsorblock
      ];
    };
  };
}
