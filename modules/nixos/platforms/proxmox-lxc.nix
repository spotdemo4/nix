{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
