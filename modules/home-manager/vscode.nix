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
        usernamehw.errorlens
        github.copilot
        golang.go
      ]) ++ (with inputs.nix-vscode-extensions.extensions.x86_64-linux; [
        vscode-marketplace.a-h.templ
        vscode-marketplace.trapfether.tailwind-raw-reorder
        vscode-marketplace.pcbowers.alpine-intellisense
      ]) ++ [
        (pkgs.catppuccin-vsc.override {
          accent = "sky";
        })
      ];
      userSettings = {
        "workbench.colorTheme" = "Catppuccin Mocha";
        "catppuccin.accentColor" = "sky";
        "workbench.editor.labelFormat" = "short";
        "workbench.tree.indent" = 16;
        "explorer.sortOrder" = "filesFirst";
        "explorer.compactFolders" = false;
        "editor.fontFamily" = "Fira Code";
        "editor.fontLigatures" = true;
        "svelte.enable-ts-plugin" = true;
        "alpine-intellisense.settings.languageScopes" = "html,templ";
      };
    };
  };
}
