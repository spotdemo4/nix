{ pkgs, ... }:
{
  home.packages = with pkgs; [
    hyprshutdown
  ];

  home.shellAliases = {
    shutdown = "hyprshutdown --top-label 'Shutting down...' --post-cmd 'shutdown --poweroff 0'";
  };
}
