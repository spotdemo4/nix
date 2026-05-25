{
  config,
  self,
  pkgs,
  ...
}:
{
  age.secrets."tailscale".file = self + /secrets/tailscale.age;

  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets."tailscale".path;
    # https://github.com/NixOS/nixpkgs/issues/438765#issuecomment-3239816312
    package = pkgs.tailscale.overrideAttrs { doCheck = false; };
  };
}
