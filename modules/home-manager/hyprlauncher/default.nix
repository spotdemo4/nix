{ config, lib, ... }:
let
  projectDesktopEntries = lib.mapAttrs (_: entry: {
    inherit (entry)
      type
      exec
      icon
      comment
      terminal
      name
      genericName
      mimeType
      categories
      startupNotify
      noDisplay
      prefersNonDefaultGPU
      settings
      actions
      ;
  }) (lib.filterAttrs (name: _: lib.hasPrefix "zed-" name) config.xdg.desktopEntries);
in
{
  options.trev.programs.hyprlauncher.enable = lib.mkEnableOption "Trev's hyprlauncher configuration";

  config = lib.mkIf config.trev.programs.hyprlauncher.enable {
    services.hyprlauncher = {
      enable = true;
      settings.ui.window_size = "500 325";
    };

    systemd.user.services.hyprlauncher.Unit.X-Restart-Triggers = lib.mkAfter [
      (builtins.hashString "sha256" (builtins.toJSON projectDesktopEntries))
    ];

    xdg.configFile."hypr/hyprtoolkit.conf".text = ''
      background = rgba(181818cc)
      accent = rgba(33ccffee)
      accent_secondary = rgba(00ff99ee)
    '';
  };
}
