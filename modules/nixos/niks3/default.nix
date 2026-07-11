{
  config,
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.trev.niks3;
  niks3Wrapper = pkgs.writeShellApplication {
    name = "niks3";
    runtimeInputs = [ inputs.niks3.packages."${pkgs.stdenv.hostPlatform.system}".default ];
    text = ''
      NIKS3_SERVER_URL="${cfg.serverUrl}"
      NIKS3_AUTH_TOKEN_FILE="${config.age.secrets."niks3".path}"
      export NIKS3_SERVER_URL NIKS3_AUTH_TOKEN_FILE
      exec niks3 "$@"
    '';
  };
in
{
  options.trev.niks3 = {
    enable = lib.mkEnableOption "niks3 client and automatic uploads";

    serverUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://niks3.trev.zip";
      description = "Niks3 server URL.";
    };

    authTokenSecretFile = lib.mkOption {
      type = lib.types.path;
      default = self + /secrets/niks3.age;
      defaultText = lib.literalExpression "self + /secrets/niks3.age";
      description = "Encrypted age file containing the Niks3 authentication token.";
    };

    autoUpload = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable automatic Niks3 uploads.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets."niks3".file = cfg.authTokenSecretFile;

    environment.systemPackages = [ niks3Wrapper ];

    services.niks3-auto-upload = lib.mkIf cfg.autoUpload {
      enable = true;
      serverUrl = cfg.serverUrl;
      authTokenFile = config.age.secrets."niks3".path;
    };
  };
}
