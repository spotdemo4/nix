let
  keys = import ./keys.nix;
in {
  "gpg.age".publicKeys = keys.local;
  "opencommit.age".publicKeys = keys.local;
  "continue.age".publicKeys = keys.local;
  "gitea-runner.age".publicKeys = keys.all;
  "tailscale.age".publicKeys = keys.all;
  "grafana.age".publicKeys = keys.all;
  "openwebui.age".publicKeys = keys.all;
  "auth-basic.age".publicKeys = keys.all;
  "auth-github.age".publicKeys = keys.all;
  "auth-cookie.age".publicKeys = keys.all;
  "auth-plex.age".publicKeys = keys.all;
  "cloudflare-dns.age".publicKeys = keys.all;
  "traefik.age".publicKeys = keys.all;
}
