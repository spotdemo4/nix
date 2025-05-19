let
  inherit (import ./keys.nix) keys;
in {
  "gitea-runner.age".publicKeys = keys;
}
