{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.trev.programs.hyprshutdown.enable = lib.mkEnableOption "Trev's Hyprshutdown configuration";

  config = lib.mkIf config.trev.programs.hyprshutdown.enable {
    home.packages = with pkgs; [
      hyprshutdown
    ];

    home.shellAliases = {
      shutdown = "hyprshutdown --top-label 'Shutting down...' --post-cmd 'shutdown --poweroff 0'";
      reboot = "hyprshutdown --top-label 'Rebooting...' --post-cmd 'reboot'";
    };
  };
}
