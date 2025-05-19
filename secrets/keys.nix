let
  local = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhbWUnHfLabigfXHSpkVv1YdrGSAoB0KXp23BsW+cZs trev@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINYjEopsO508BUVU2wu/RUP97psEdxzUhqH+kvvj2M8x trev@laptop"
  ];
  remote = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA5QS/lsWUsrRtEhA2jVYYyevbeWOePNugR3QKHTZ+aG trev@build"
  ];
in {
  local_keys = local;
  remote_keys = remote;
  keys = local ++ remote;
}
