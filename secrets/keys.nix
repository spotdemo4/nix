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

  # Keys for servers
  ai = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIipGzt2u19Aon2qZaw8aVG1+ZRevX5t2LrpQBwt/WCG root@ai";
  build = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxD3eccbwfEkahm6zLR+JIVnshwSBFO3dX3roFHndgp root@build";
  game = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHU2UCuSMdo2GYPU4R0pkPse5efZEAjOSuuf+nJYpeVd root@game";
  gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQeBo8YspGiTDH3xhIg0vTWzwIOJtk3VeE6PQ97lyu4 root@gateway";
  mail = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmShUk0TcJB2JYDTYCDDFWOoSNfvPd2Ulxq083iFNqy root@mail";
  media = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIInThVD92YRSlKIxCdhqLwsGkmvRUvRQFHwOuCQEOQlh root@media";
  monitor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBF162KlIQ0KM4MPHmSi9UEsDrVsdgiTyAdWSAOE87WE root@monitor";
  remote = [
    ai
    build
    game
    gateway
    mail
    media
    monitor
  ];

  all = local ++ remote;
}
