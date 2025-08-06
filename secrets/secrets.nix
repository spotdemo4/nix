let
  keys = import ./keys.nix;
in {
  "auth-basic.age".publicKeys = keys.all;
  "auth-cookie.age".publicKeys = keys.all;
  "auth-github.age".publicKeys = keys.all;
  "auth-plex.age".publicKeys = keys.all;
  "claude.age".publicKeys = keys.all;
  "cloudflare-dns.age".publicKeys = keys.all;
  "codeberg.age".publicKeys = keys.all;
  "continue.age".publicKeys = keys.local;
  "curseforge.age".publicKeys = keys.all;
  "discord-openrouter.age".publicKeys = keys.all;
  "gitea-quanta.age".publicKeys = keys.all;
  "gitea.age".publicKeys = keys.all;
  "github-runner.age".publicKeys = keys.all;
  "gpg.age".publicKeys = keys.local;
  "grafana.age".publicKeys = keys.all;
  "mods.age".publicKeys = keys.local;
  "openrouter.age".publicKeys = keys.all;
  "openwebui.age".publicKeys = keys.all;
  "tailscale.age".publicKeys = keys.all;
  "traefik.age".publicKeys = keys.all;
}
