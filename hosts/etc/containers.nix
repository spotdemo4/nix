{
  config,
  self,
  ...
}:
{
  imports = [
    (self + /modules/container/cobalt)
    (self + /modules/container/cobalt-web)
    (self + /modules/container/cobalt-youtube)
    (self + /modules/container/cliproxyapi)
    (self + /modules/container/crowdsec)
    (self + /modules/container/gluetun)
    (self + /modules/container/nix-shield)
    (self + /modules/container/portainer-agent)
    (self + /modules/container/postgresql)
    (self + /modules/container/shlink)
    (self + /modules/container/shlink-web)
    (self + /modules/container/solid-toast)
    (self + /modules/container/traefik-kop)
  ];

  virtualisation.quadlet = {
    secrets = {
      protonvpn-cobalt.file = toString (self + /secrets/protonvpn-cobalt.age);
      shlink-postgresql.file = toString (self + /secrets/shlink-postgresql.age);
    };
  };

  trev.containers = {
    cobalt.enable = true;
    cobalt-web.enable = true;
    cliproxyapi = {
      enable = true;
      openaiCompatibility = [
        {
          name = "openrouter";
          # Prefer OAuth credentials; only fall back to the same model through OpenRouter.
          priority = -10;
          baseUrl = "https://openrouter.ai/api/v1";
          apiKeyFile = self + /secrets/openrouter.age;
          models = [
            {
              name = "z-ai/glm-5.3-flash";
              alias = "glm-5.3-flash";
            }
            {
              name = "openai/gpt-6-astra";
              alias = "gpt-6-astra";
            }
            {
              name = "openai/gpt-6-sol";
              alias = "gpt-6-sol";
            }
            {
              name = "openai/gpt-6-luna";
              alias = "gpt-6-luna";
            }
            {
              name = "anthropic/claude-haiku-4.5";
              alias = "claude-haiku-4-5-20251001";
            }
            {
              name = "anthropic/claude-opus-5.5";
              alias = "claude-opus-5-5";
            }
            {
              name = "anthropic/claude-sonnet-5";
              alias = "claude-sonnet-5";
            }
            {
              name = "anthropic/claude-fable-5.1";
              alias = "claude-fable-5-1";
            }
          ];
        }
      ];
    };
    crowdsec.enable = true;
    nix-shield.enable = true;
    portainer-agent.enable = true;
    shlink.enable = true;
    shlink-web.enable = true;
    solid-toast.enable = true;

    gluetun = {
      enable = true;
      instances.cobalt = {
        enable = true;
        secret = config.virtualisation.quadlet.secrets.protonvpn-cobalt;
        ports = [ "9000" ];
        environments = {
          VPN_SERVICE_PROVIDER = "protonvpn";
          VPN_TYPE = "wireguard";
          SERVER_CITIES = "Chicago,Toronto";
          STREAM_ONLY = "on";
        };
      };
    };

    postgresql = {
      enable = true;
      instances.shlink = {
        enable = true;
        database = "shlink";
        username = "shlink";
        networks = [ config.virtualisation.quadlet.networks.shlink.ref ];
        passwordSecret = config.virtualisation.quadlet.secrets.shlink-postgresql;
      };
    };

    traefik-kop = {
      enable = true;
      ip = "10.10.10.114";
    };
  };
}
