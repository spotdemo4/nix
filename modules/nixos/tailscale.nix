{
  config,
  self,
  ...
}: {
  age.secrets."tailscale".file = self + /secrets/tailscale.age;

  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets."tailscale".path;
  };
}
