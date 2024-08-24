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
      };

      safe.directory = "/etc/nixos";
    };
  };
}
