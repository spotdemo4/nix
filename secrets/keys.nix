let
  local_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhbWUnHfLabigfXHSpkVv1YdrGSAoB0KXp23BsW+cZs trev@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINYjEopsO508BUVU2wu/RUP97psEdxzUhqH+kvvj2M8x trev@laptop"
  ];
  remote_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxD3eccbwfEkahm6zLR+JIVnshwSBFO3dX3roFHndgp root@build"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIInThVD92YRSlKIxCdhqLwsGkmvRUvRQFHwOuCQEOQlh root@media"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQeBo8YspGiTDH3xhIg0vTWzwIOJtk3VeE6PQ97lyu4 root@gateway"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBF162KlIQ0KM4MPHmSi9UEsDrVsdgiTyAdWSAOE87WE root@monitor"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIipGzt2u19Aon2qZaw8aVG1+ZRevX5t2LrpQBwt/WCG root@ai"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHU2UCuSMdo2GYPU4R0pkPse5efZEAjOSuuf+nJYpeVd root@game"
  ];
in {
  local = local_keys;
  remote = remote_keys;
  all = local_keys ++ remote_keys;
}
