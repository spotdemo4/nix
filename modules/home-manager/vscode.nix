{ lib, config, pkgs, ... }:
 
{
  options.vscode-conf = {
    enable = lib.mkEnableOption "enable vscode config";
  };

  config = lib.mkIf config.vscode-conf.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        svelte.svelte-vscode
        jnoortheen.nix-ide
        catppuccin.catppuccin-vsc
        usernamehw.errorlens
        github.copilot
      ];
    };
  };
}
