let
  keys = import ./keys.nix;
in {
  "gpg.age".publicKeys = keys.local;
  "gitea-runner.age".publicKeys = keys.all;
  "authelia-session.age".publicKeys = keys.all;
  "authelia-hmac.age".publicKeys = keys.all;
  "authelia-private-key.age".publicKeys = keys.all;
  "tailscale.age".publicKeys = keys.all;
  "grafana.age".publicKeys = keys.all;
  "authelia-env.age".publicKeys = keys.all;
  "openwebui.age".publicKeys = keys.all;
  "authentik-postgres.age".publicKeys = keys.all;
  "authentik-server.age".publicKeys = keys.all;
  "authentik-token-user.age".publicKeys = keys.all;
  "authentik-token-admin.age".publicKeys = keys.all;
  "github-oauth-secret.age".publicKeys = keys.all;
  "cookie-secret.age".publicKeys = keys.all;
}
