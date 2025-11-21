{ ... }:
{
  programs.git = {
    enable = true;
    config = {
      init = {
        defaultBranch = "main";
      };

      user = {
        name = "trev";
        email = "me@trev.xyz";
        signingkey = "3AAF87E0B1A2AC36";
      };

      commit.gpgsign = "true";
      tag.gpgSign = "true";

      safe.directory = "/etc/nixos";
    };
  };
}
