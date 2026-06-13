{
  self,
  config,
  pkgs,
  inputs,
  ...
}:
let
  niks3Wrapper = pkgs.writeShellApplication {
    name = "niks3";
    runtimeInputs = [ inputs.niks3.packages."${pkgs.stdenv.hostPlatform.system}".default ];
    text = ''
      NIKS3_SERVER_URL="https://niks3.trev.zip"
      NIKS3_AUTH_TOKEN_FILE="${config.age.secrets."niks3".path}"
      export NIKS3_SERVER_URL NIKS3_AUTH_TOKEN_FILE
      exec niks3 "$@"
    '';
  };
in
{
  age.secrets."niks3".file = self + /secrets/niks3.age;

  environment.systemPackages = [
    niks3Wrapper
  ];
}
