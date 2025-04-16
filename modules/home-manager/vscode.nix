{ pkgs, inputs, ... }:
 
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = (with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        usernamehw.errorlens
        golang.go
      ]) ++ (with inputs.nix-vscode-extensions.extensions.x86_64-linux; [
        vscode-marketplace.svelte.svelte-vscode
        vscode-marketplace.continue.continue
        vscode-marketplace.bradlc.vscode-tailwindcss
        vscode-marketplace.zxh404.vscode-proto3
        vscode-marketplace.dorzey.vscode-sqlfluff
        vscode-marketplace.oracle.sql-developer
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
        "sqldeveloper.sqlHistory.historyLimit" = 500;
        "sqldeveloper.telemetry.enabled" = true;
      };
    };
    mutableExtensionsDir = false;
  };
}
