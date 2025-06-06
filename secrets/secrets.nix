let
  keys = import ./keys.nix;
in {
  "gpg.age".publicKeys = keys.local;
  "gitea-runner.age".publicKeys = keys.all;
  "tailscale.age".publicKeys = keys.all;
  "grafana.age".publicKeys = keys.all;
  "openwebui.age".publicKeys = keys.all;
  "oauth2-github.age".publicKeys = keys.all;
  "oauth2-cookie.age".publicKeys = keys.all;
  "auth-basic-env.age".publicKeys = keys.all;
  "auth-basic.age".publicKeys = keys.all;
}
