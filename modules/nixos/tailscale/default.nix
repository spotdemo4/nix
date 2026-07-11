{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.trev.tailscale;
in
{
  options.trev.tailscale = {
    enable = lib.mkEnableOption "Tailscale with the host authentication secret";

    authKeySecretFile = lib.mkOption {
      type = lib.types.path;
      default = self + /secrets/tailscale.age;
      defaultText = lib.literalExpression "self + /secrets/tailscale.age";
      description = "Encrypted age file containing the Tailscale authentication key.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets."tailscale".file = cfg.authKeySecretFile;

    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets."tailscale".path;
      # https://github.com/NixOS/nixpkgs/issues/438765#issuecomment-3239816312
      package = pkgs.tailscale.overrideAttrs { doCheck = false; };
    };
  };
}
