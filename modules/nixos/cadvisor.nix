{...}: {
  services.cadvisor = {
    enable = true;
    port = 8069;
  };
}
