let
  addresses = {
    gateway = "10.10.10.105";
    debian = "10.10.10.106";
    media = "10.10.10.107";
    build = "10.10.10.108";
    monitor = "10.10.10.109";
    bench = "10.10.10.110";
    game = "10.10.10.111";
    mail = "10.10.10.112";
    files = "10.10.10.113";
    etc = "10.10.10.114";
    dev = "10.10.10.115";
  };

  hosts = builtins.listToAttrs (
    builtins.map (hostname: {
      name = addresses.${hostname};
      value = [ hostname ];
    }) (builtins.attrNames addresses)
  );
in
{
  inherit addresses hosts;
}
