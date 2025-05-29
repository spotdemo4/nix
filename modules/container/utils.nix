{
  pkgs,
  config,
  ...
}: rec {
  mkVolume = name: {
    system.activationScripts."${name}" = let
      docker = config.virtualisation.oci-containers.backend;
      dockerBin = "${pkgs.${docker}}/bin/${docker}";
    in ''
      ${dockerBin} volume inspect ${name} >/dev/null 2>&1 || ${dockerBin} volume create ${name}
    '';
  };

  mkNetwork = name: {
    system.activationScripts."${name}" = let
      docker = config.virtualisation.oci-containers.backend;
      dockerBin = "${pkgs.${docker}}/bin/${docker}";
    in ''
      ${dockerBin} network inspect ${name} >/dev/null 2>&1 || ${dockerBin} network create ${name}
    '';
  };

  toEnvStrings = prefix: attrs:
    builtins.concatLists (
      builtins.attrValues (
        builtins.mapAttrs (
          k: v:
            if builtins.isAttrs v
            then toEnvStrings (prefix ++ [k]) v
            else ["${builtins.concatStringsSep "." (prefix ++ [k])}=${toString v}"]
        )
        attrs
      )
    );
}
