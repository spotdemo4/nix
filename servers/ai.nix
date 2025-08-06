{self, ...}: {
  imports =
    [
      (self + /hosts/lxc/configuration.nix)
    ]
    ++ map (x: self + /modules/container/${x}.nix) [
      # Containers to import
      "context7"
      "discord-openrouter"
      "intel-gpu-exporter"
      "ollama"
      "portainer-agent"
      "traefik-kop"
    ];

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
