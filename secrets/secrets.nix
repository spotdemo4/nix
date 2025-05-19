let
  inherit (import ./keys.nix) keys;
in {
  "gitea-runner.age".publicKeys = keys;
  "authelia-session.age".publicKeys = keys;
  "authelia-hmac.age".publicKeys = keys;
  "authelia-private-key.age".publicKeys = keys;
}
