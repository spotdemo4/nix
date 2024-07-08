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
        golang.go
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "templ";
          publisher = "a-h";
          version = "0.0.26";
          sha256 = "/77IO+WjgWahUrj6xVl0tkvICh9Cy+MtfH2dewxH8LE=";
        }
      ];
    };
  };
}
