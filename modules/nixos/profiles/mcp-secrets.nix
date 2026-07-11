{
  config,
  lib,
  self,
  ...
}:
let
  secretFiles = {
    context7 = self + /secrets/context7.age;
    forgejo-mcp = self + /secrets/forgejo-mcp.age;
    github = self + /secrets/github.age;
    kagi = self + /secrets/kagi.age;
  };
in
{
  age.secrets = lib.mapAttrs (_: file: {
    inherit file;
    owner = "trev";
    group = "trev";
    mode = "0400";
  }) secretFiles;

  home-manager.users.trev.trev.mcp.secretPaths = lib.mapAttrs (
    name: _: config.age.secrets.${name}.path
  ) secretFiles;
}
