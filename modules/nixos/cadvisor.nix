{ ... }:
{
  services.cadvisor = {
    enable = true;
    port = 8069;
    listenAddress = "0.0.0.0";
  };
}
