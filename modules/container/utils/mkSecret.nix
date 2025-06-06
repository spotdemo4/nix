{
  pkgs,
  config,
}: {
  mkSecret = name: path: {
    ref = name;
    script = let
      docker = config.virtualisation.oci-containers.backend;
      dockerBin = "${pkgs.${docker}}/bin/${docker}";
    in ''
      ${dockerBin} secret create --replace=true ${name} ${path}
    '';
  };
}
