{self, ...}: {
  imports =
    [
      (self + /hosts/lxc/configuration.nix)
    ]
    ++ map (x: self + /modules/nixos/${x}.nix) [
      # Programs to import
      "update"
    ]
    ++ map (x: self + /modules/container/${x}.nix) [
      # Containers to import
      "portainer-agent"
      "traefik-kop"
      "ollama"
      "intel-gpu-exporter"
      "context7"
    ];

  networking.hostName = "ai";

  # Update script
  update = {
    enable = true;
    hostname = "ai";
    user = "trev";
  };

  # Traefik mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.110";
  };

  intel-gpu-exporter = {
    enable = true;
    card = "card1";
    render = "renderD129";
  };
}
