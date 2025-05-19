let
  inherit (./keys.nix) keys;
in {
  "gitea-runner".publicKeys = keys;
}
