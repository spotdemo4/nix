{ pkgs, ... }:
{
  home.packages = with pkgs; [
    hyprshutdown
  ];

  home.shellAliases = {
    shutdown = "hyprshutdown --top-label 'Shutting down...' --post-cmd 'shutdown --poweroff 0'";
    reboot = "hyprshutdown --top-label 'Rebooting...' --post-cmd 'reboot'";
  };
}
