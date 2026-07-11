{
  pkgs,
  self,
  ...
}:
{
  users.users.trev = {
    isNormalUser = true;
    description = "trev";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = (import (self + /secrets/keys.nix)).sshClients;
  };
}
