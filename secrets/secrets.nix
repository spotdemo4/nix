let
  keys = import ./keys.nix;
in
{
  "tailscale.age".publicKeys = keys.all;

  # ai server
  "discord-openrouter.age".publicKeys = keys.local ++ [ keys.ai ];
  "openrouter.age".publicKeys = keys.local ++ [ keys.ai ];
  "openwebui.age".publicKeys = keys.local ++ [ keys.ai ];

  # build server
  "codeberg.age".publicKeys = keys.local ++ [ keys.build ];
  "gitea-quanta.age".publicKeys = keys.local ++ [ keys.build ];
  "gitea.age".publicKeys = keys.local ++ [ keys.build ];
  "github-runner.age".publicKeys = keys.local ++ [ keys.build ];

  # file server
  "attic.age".publicKeys = keys.local ++ [ keys.files ];
  "copyparty.age".publicKeys = keys.local ++ [ keys.files ];

  # game server
  "curseforge.age".publicKeys = keys.local ++ [ keys.game ];
  "whiteout.age".publicKeys = keys.local ++ [ keys.game ];

  # gateway server
  "auth-cookie.age".publicKeys = keys.local ++ [ keys.gateway ];
  "auth-github.age".publicKeys = keys.local ++ [ keys.gateway ];
  "auth-plex.age".publicKeys = keys.local ++ [ keys.gateway ];
  "cloudflare-dns.age".publicKeys = keys.local ++ [ keys.gateway ];
  "mantrae-password.age".publicKeys = keys.local ++ [ keys.gateway ];
  "mantrae-secret.age".publicKeys = keys.local ++ [ keys.gateway ];
  "traefik.age".publicKeys = keys.local ++ [ keys.gateway ];

  # mail server
  "mysql-roundcube.age".publicKeys = keys.local ++ [ keys.mail ];

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

  # local only
  "auth-basic.age".publicKeys = keys.local;
  "continue.age".publicKeys = keys.local;
  "gpg.age".publicKeys = keys.local;
  "mods.age".publicKeys = keys.local;
  "attic-trev.age".publicKeys = keys.local;
}
