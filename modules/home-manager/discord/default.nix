{ config, lib, ... }:
{
  options.trev.programs.discord.enable = lib.mkEnableOption "Trev's Discord web app";

  config = lib.mkIf config.trev.programs.discord.enable {
    xdg.desktopEntries.discord = {
      name = "Discord";
      genericName = "Discord";
      exec = "chromium --app=https://discord.com/channels/104979971667197952/560031938845605909 --enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo --allowliste­d-extension-id=clngdbkpkp­eebahjckkj­fobafhncgm­ne";
      terminal = false;
      categories = [
        "Application"
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "text/xml"
      ];
    };
  };
}
