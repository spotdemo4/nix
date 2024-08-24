{ pkgs, ... }:
 
{
  programs.chromium = {
    enable = true;
    package = pkgs.vivaldi;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # UBlock Origin
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # Sponsorblock
      { id = "clngdbkpkpeebahjckkjfobafhncgmne"; } # Stylus
    ];
  };
}
