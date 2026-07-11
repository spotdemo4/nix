{
  pkgs,
  self,
  ...
}:
{
  imports = [
    ./common.nix
    (self + /modules/util/secrets)
  ]
  ++ map (module: self + /modules/nixos/${module}) [
    "cadvisor"
  ];

  environment.systemPackages = with pkgs; [
    iperf
    kitty
    traceroute
  ];

  users = {
    groups.trev.gid = 1000;
    users.trev = {
      uid = 1000;
      group = "trev";
      extraGroups = [
        "wheel"
        "podman"
        "video"
        "render"
      ];
    };
  };

  virtualisation.podman = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
    };
  };

  virtualisation.quadlet = {
    autoEscape = true;
    autoUpdate.enable = true;
  };
}
