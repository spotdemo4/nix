let
  keys = import ./keys.nix;
in
{
  "tailscale.age".publicKeys = keys.all;

  # build server
  "builder-key.age".publicKeys = keys.local ++ [ keys.build ];
  "forgejo.age".publicKeys = keys.local ++ [ keys.build ];
  "forgejo-org.age".publicKeys = keys.local ++ [ keys.build ];
  "forgejo-template.age".publicKeys = keys.local ++ [ keys.build ];
  "github-runner.age".publicKeys = keys.local ++ [ keys.build ];

  # etc server
  "discord-openrouter.age".publicKeys = keys.local ++ [ keys.etc ];
  "geolite.age".publicKeys = keys.local ++ [ keys.etc ];
  "openrouter.age".publicKeys = keys.local ++ [ keys.etc ];
  "protonvpn-cobalt.age".publicKeys = keys.local ++ [ keys.etc ];
  "shlink.age".publicKeys = keys.local ++ [ keys.etc ];
  "shlink-postgresql.age".publicKeys = keys.local ++ [ keys.etc ];

  # file server
  "copyparty.age".publicKeys = keys.local ++ [ keys.files ];
  "garage-admin.age".publicKeys = keys.local ++ [ keys.files ];
  "garage-metrics.age".publicKeys = keys.local ++ [ keys.files ];
  "garage-nix-key.age".publicKeys = keys.local ++ [ keys.files ];
  "garage-nix-secret.age".publicKeys = keys.local ++ [ keys.files ];
  "garage-rpc.age".publicKeys = keys.local ++ [ keys.files ];
  "immich-postgresql.age".publicKeys = keys.local ++ [ keys.files ];
  "niks3-database-url.age".publicKeys = keys.local ++ [ keys.files ];
  "niks3-postgresql.age".publicKeys = keys.local ++ [ keys.files ];
  "niks3-signing-key.age".publicKeys = keys.local ++ [ keys.files ];
  "rsyncd.age".publicKeys = keys.local ++ [ keys.files ];

  # game server
  "curseforge.age".publicKeys = keys.local ++ [ keys.game ];

  # gateway server
  "cloudflare-dns.age".publicKeys = keys.local ++ [ keys.gateway ];
  "cloudflare-turnstile-secret-key.age".publicKeys = keys.local ++ [ keys.gateway ];
  "cloudflare-turnstile-site-key.age".publicKeys = keys.local ++ [ keys.gateway ];
  "crowdsec.age".publicKeys = keys.local ++ [ keys.gateway ];
  "user-admin.age".publicKeys = keys.local ++ [ keys.gateway ];
  "user-trev.age".publicKeys = keys.local ++ [ keys.gateway ];

  # media server
  "embedder-discord.age".publicKeys = keys.local ++ [ keys.media ];
  "embedder-instagram.age".publicKeys = keys.local ++ [ keys.media ];
  "embedder-reddit.age".publicKeys = keys.local ++ [ keys.media ];
  "embedder-tiktok.age".publicKeys = keys.local ++ [ keys.media ];
  "embedder-x.age".publicKeys = keys.local ++ [ keys.media ];
  "password.age".publicKeys = keys.local ++ [ keys.media ];
  "protonvpn-qbittorrent.age".publicKeys = keys.local ++ [ keys.media ];
  "radarr.age".publicKeys = keys.local ++ [ keys.media ];
  "sonarr.age".publicKeys = keys.local ++ [ keys.media ];

  # monitor server
  "grafana.age".publicKeys = keys.local ++ [ keys.monitor ];

  # builds
  "niks3.age".publicKeys = keys.local ++ [
    keys.files
    keys.build
  ];

  # development machines
  "context7.age".publicKeys = keys.development;
  "forgejo-mcp.age".publicKeys = keys.development;
  "github.age".publicKeys = keys.development;
  "kagi.age".publicKeys = keys.development;

  # local only
  "continue.age".publicKeys = keys.local;
  "gpg.age".publicKeys = keys.local;
  "mods.age".publicKeys = keys.local;
}
