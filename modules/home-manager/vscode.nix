{ lib, config, pkgs, inputs, ... }:
 
{
  options.vscode-conf = {
    enable = lib.mkEnableOption "enable vscode config";
  };

  config = lib.mkIf config.vscode-conf.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = (with pkgs.vscode-extensions; [
        svelte.svelte-vscode
        jnoortheen.nix-ide
        catppuccin.catppuccin-vsc
        usernamehw.errorlens
        github.copilot
        golang.go
      ]) ++ (with inputs.nix-vscode-extensions.extensions.x86_64-linux; [
        open-vsx.a-h.templ
        vscode-marketplace.trapfether.tailwind-raw-reorder
      ]);
    };
  };
}
