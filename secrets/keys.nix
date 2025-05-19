let
  local = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhbWUnHfLabigfXHSpkVv1YdrGSAoB0KXp23BsW+cZs trev@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINYjEopsO508BUVU2wu/RUP97psEdxzUhqH+kvvj2M8x trev@laptop"
  ];
  remote = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxD3eccbwfEkahm6zLR+JIVnshwSBFO3dX3roFHndgp root@build"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIInThVD92YRSlKIxCdhqLwsGkmvRUvRQFHwOuCQEOQlh root@media"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQeBo8YspGiTDH3xhIg0vTWzwIOJtk3VeE6PQ97lyu4 root@gateway"
  ];
in {
  local_keys = local;
  remote_keys = remote;
  keys = local ++ remote;
}
