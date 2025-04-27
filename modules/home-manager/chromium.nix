{pkgs, ...}: {
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;
    extensions = [
      {id = "ddkjiahejlhfcafbddmgiahcphecmpfh";} # UBlock Origin Lite
      {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden
      {id = "mnjggcdmjocbbbhaepdhchncahnbgone";} # Sponsorblock
      {id = "clngdbkpkpeebahjckkjfobafhncgmne";} # Stylus
    ];
  };

  catppuccin.chromium = {
    enable = true;
    flavor = "mocha";
  };
}
