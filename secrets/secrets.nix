let
  keys = import ./keys.nix;
in
{
  "tailscale.age".publicKeys = keys.all;

  # build server
  "codeberg.age".publicKeys = keys.local ++ [ keys.build ];
  "gitea-quanta.age".publicKeys = keys.local ++ [ keys.build ];
  "gitea.age".publicKeys = keys.local ++ [ keys.build ];
  "github-runner.age".publicKeys = keys.local ++ [ keys.build ];
  "org-token.age".publicKeys = keys.local ++ [ keys.build ];
  "quantadev-token.age".publicKeys = keys.local ++ [ keys.build ];
  "repo-token.age".publicKeys = keys.local ++ [ keys.build ];

  # etc server
  "anubis.age".publicKeys = keys.local ++ [ keys.etc ];
  "discord-openrouter.age".publicKeys = keys.local ++ [ keys.etc ];
  "geolite.age".publicKeys = keys.local ++ [ keys.etc ];
  "openrouter.age".publicKeys = keys.local ++ [ keys.etc ];
  "openwebui.age".publicKeys = keys.local ++ [ keys.etc ];
  "protonvpn-cobalt.age".publicKeys = keys.local ++ [ keys.etc ];
  "shlink.age".publicKeys = keys.local ++ [ keys.etc ];

  # file server
  "attic.age".publicKeys = keys.local ++ [ keys.files ];
  "copyparty.age".publicKeys = keys.local ++ [ keys.files ];
  "versitygw.age".publicKeys = keys.local ++ [ keys.files ];

  # game server
  "curseforge.age".publicKeys = keys.local ++ [ keys.game ];
  "whiteout.age".publicKeys = keys.local ++ [ keys.game ];

  # gateway server
  "cloudflare-dns.age".publicKeys = keys.local ++ [ keys.gateway ];
  "crowdsec.age".publicKeys = keys.local ++ [ keys.gateway ];
  "user-admin.age".publicKeys = keys.local ++ [ keys.gateway ];
  "user-trev.age".publicKeys = keys.local ++ [ keys.gateway ];

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
  "auth.age".publicKeys = keys.local;
  "continue.age".publicKeys = keys.local;
  "gpg.age".publicKeys = keys.local;
  "mods.age".publicKeys = keys.local;
  "attic-trev.age".publicKeys = keys.local;
}
