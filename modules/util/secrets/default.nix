{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.secrets;
  docker = config.virtualisation.oci-containers.backend;
  dockerBin = "${pkgs.${docker}}/bin/${docker}";
in
{
  options.secrets = mkOption {
    default = { };
    description = "Secrets to be created for docker";
    type = types.attrsOf (types.submodule (import ./secret.nix));
  };

  config = mkIf (cfg != { }) {
    age.secrets = mapAttrs (name: secret: {
      file = secret.file;
    }) cfg;

    system.activationScripts = mapAttrs (name: _: ''
      ${dockerBin} secret create --replace=true ${name} ${config.age.secrets."${name}".path}
    '') cfg;
  };
}
