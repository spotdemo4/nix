{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.secrets;
in {
  options.secrets = {
    enable = mkEnableOption "create docker secrets";

    secret = mkOption {
      type = types.attrsOf (types.str);
      description = ''
        An attribute set of secrets to create. Each attribute key is the name of the secret,
        and the value is the path to the file containing the secret.
      '';
    };
  };

  config = mkIf cfg.enable {
    age.secrets =
      mapAttrs (name: path: {
        file = path;
      })
      cfg.secret;

    system.activationScripts = let
      docker = config.virtualisation.oci-containers.backend;
      dockerBin = "${pkgs.${docker}}/bin/${docker}";
    in
      mapAttrs (
        name: _: ''
          ${dockerBin} secret create --replace=true ${name} ${config.age.secrets."${name}".path}
        ''
      )
      cfg.secret;
  };
}
