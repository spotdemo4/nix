{ lib, config, pkgs, ... }:
 
{
  options.postgres-nix = {
    enable = lib.mkEnableOption "enable postgres";
  };

  config = lib.mkIf config.postgres-nix.enable {
    services.postgresql = {
      enable = true;
    };
  };
}
