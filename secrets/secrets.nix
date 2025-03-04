let
  trev-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhbWUnHfLabigfXHSpkVv1YdrGSAoB0KXp23BsW+cZs";
  users = [ trev-desktop ];

  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPVS4TRJ2LrjQNkRqW5XnP6tbNRE18LJurGQwZ9GEKj2";
  systems = [ desktop ];
in
{
  "vllm-api.age".publicKeys = users ++ systems;
}