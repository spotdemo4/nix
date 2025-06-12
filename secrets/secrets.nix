let
  keys = import ./keys.nix;
in {
  "auth-basic.age".publicKeys = keys.all;
  "auth-cookie.age".publicKeys = keys.all;
  "auth-github.age".publicKeys = keys.all;
  "auth-plex.age".publicKeys = keys.all;
  "cloudflare-dns.age".publicKeys = keys.all;
  "continue.age".publicKeys = keys.local;
  "gitea-runner.age".publicKeys = keys.all;
  "gpg.age".publicKeys = keys.local;
  "grafana.age".publicKeys = keys.all;
  "mods.age".publicKeys = keys.local;
  "openwebui.age".publicKeys = keys.all;
  "tailscale.age".publicKeys = keys.all;
  "traefik.age".publicKeys = keys.all;
}
