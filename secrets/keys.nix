rec {
  # Keys for personal devices
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhbWUnHfLabigfXHSpkVv1YdrGSAoB0KXp23BsW+cZs trev@desktop";
  htpc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK9scZbR7KIVfWlZkBlXDAK4ZEwy7BXy3mnvQKushd2P trev@htpc";
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINYjEopsO508BUVU2wu/RUP97psEdxzUhqH+kvvj2M8x trev@laptop";
  local = [
    desktop
    htpc
    laptop
  ];

  # Login keys accepted by the trev account on each host.
  sshClients = local;

  # Keys for servers
  bench = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4DjeXkDXdEEe0vAHXf43Mf/VRTqmURJbAGcDUmIOZP root@bench";
  build = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxD3eccbwfEkahm6zLR+JIVnshwSBFO3dX3roFHndgp root@build";
  dev = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIwyDBj9JupkwRRNAgwOpAYpQ4CoDnz4YuSYCNF73c18 root@dev";
  etc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOZQ2A2h0VZLdBFb8XwgaBCuHryIFq8CWHE3r+H/fo1Q root@etc";
  files = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+Y5auXXHIgssGrfbUWRhtseilFnhHxsC8/s8AI+Uw7 root@files";
  game = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHU2UCuSMdo2GYPU4R0pkPse5efZEAjOSuuf+nJYpeVd root@game";
  gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQeBo8YspGiTDH3xhIg0vTWzwIOJtk3VeE6PQ97lyu4 root@gateway";
  mail = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmShUk0TcJB2JYDTYCDDFWOoSNfvPd2Ulxq083iFNqy root@mail";
  media = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIInThVD92YRSlKIxCdhqLwsGkmvRUvRQFHwOuCQEOQlh root@media";
  monitor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBF162KlIQ0KM4MPHmSi9UEsDrVsdgiTyAdWSAOE87WE root@monitor";
  remote = [
    bench
    build
    etc
    files
    game
    gateway
    mail
    media
    monitor
  ];

  development = local ++ [ dev ];

  all = sshClients ++ remote;
}
