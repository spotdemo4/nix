let
  keys = import ./keys.nix;
in {
  "gitea-runner.age".publicKeys = keys.all;
  "authelia-session.age".publicKeys = keys.all;
  "authelia-hmac.age".publicKeys = keys.all;
  "authelia-private-key.age".publicKeys = keys.all;
  "tailscale.age".publicKeys = keys.all;
  "grafana.age".publicKeys = keys.all;
}
