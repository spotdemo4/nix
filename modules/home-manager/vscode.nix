{ pkgs, inputs, ... }:
 
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = (with pkgs.vscode-extensions; [
      svelte.svelte-vscode
      jnoortheen.nix-ide
      usernamehw.errorlens
      golang.go
      gleam.gleam
      continue.continue
      ms-vscode.cpptools
      ms-dotnettools.csdevkit
    ]) ++ (with inputs.nix-vscode-extensions.extensions.x86_64-linux; [
      vscode-marketplace.a-h.templ
      vscode-marketplace.trapfether.tailwind-raw-reorder
      vscode-marketplace.pcbowers.alpine-intellisense
      vscode-marketplace.peterj.proto
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
    mutableExtensionsDir = false;
  };
}
