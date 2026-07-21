{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks;
in
{
  imports = [
    (self + /modules/container/copyparty)
    (self + /modules/container/forgejo)
    (self + /modules/container/garage)
    (self + /modules/container/immich)
    (self + /modules/container/immich-postgresql)
    (self + /modules/container/niks3)
    (self + /modules/container/portainer-agent)
    (self + /modules/container/postgresql)
    (self + /modules/container/rsyncd)
    (self + /modules/container/syncthing)
    (self + /modules/container/traefik-kop)
    (self + /modules/container/valkey)
  ];

  virtualisation.quadlet = {
    secrets = {
      immich-postgresql.file = toString (self + /secrets/immich-postgresql.age);
      niks3-database-url.file = toString (self + /secrets/niks3-database-url.age);
      niks3-postgresql.file = toString (self + /secrets/niks3-postgresql.age);
    };
  };

  trev.containers = {
    copyparty.enable = true;
    forgejo.enable = true;
    garage.enable = true;
    immich.enable = true;

    immich-postgresql = {
      enable = true;
      networks = [ networks.immich.ref ];
      passwordSecret = config.virtualisation.quadlet.secrets.immich-postgresql;
    };

    niks3 = {
      enable = true;
      databaseUrlSecret = config.virtualisation.quadlet.secrets.niks3-database-url;
    };
    portainer-agent.enable = true;
    rsyncd.enable = true;
    syncthing.enable = true;

    postgresql = {
      enable = true;
      instances.niks3 = {
        enable = true;
        database = "niks3";
        username = "niks3";
        networks = [ networks.niks3.ref ];
        passwordSecret = config.virtualisation.quadlet.secrets.niks3-postgresql;
      };
    };

    traefik-kop = {
      enable = true;
      ip = "10.10.10.113";
    };

    valkey = {
      enable = true;
      instances.immich = {
        enable = true;
        networks = [ networks.immich.ref ];
      };
    };
  };
}
