{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # UBlock Origin
      { id = "bkkmolkhemgaeaeggcmfbghljjjoofoh"; } # Catppuccin Chrome Theme
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # Sponsorblock
      { id = "clngdbkpkpeebahjckkjfobafhncgmne"; } # Stylus
    ];
  };
}
