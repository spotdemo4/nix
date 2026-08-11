{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.trev.programs.chromium.enable = lib.mkEnableOption "Trev's Chromium configuration";

  config = lib.mkIf config.trev.programs.chromium.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.chromium;
      commandLineArgs = [
        "--ozone-platform=wayland"
        "--enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,AcceleratedVideoEncoder"
      ];
      extensions = [
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # UBlock Origin Lite
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # Sponsorblock
        { id = "clngdbkpkpeebahjckkjfobafhncgmne"; } # Stylus
      ];
    };

    catppuccin.chromium = {
      enable = true;
      flavor = "mocha";
    };
  };
}
