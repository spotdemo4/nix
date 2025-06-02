{
  pkgs,
  inputs,
  ...
}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions =
        (with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          usernamehw.errorlens
          golang.go
          ms-python.python
          charliermarsh.ruff
        ])
        ++ (with inputs.nix-vscode-extensions.extensions.x86_64-linux; [
          vscode-marketplace.svelte.svelte-vscode
          vscode-marketplace.continue.continue
          vscode-marketplace.bradlc.vscode-tailwindcss
          vscode-marketplace.dorzey.vscode-sqlfluff
          vscode-marketplace.dbaeumer.vscode-eslint
          vscode-marketplace.esbenp.prettier-vscode
          vscode-marketplace.kamadorueda.alejandra
          vscode-marketplace.bufbuild.vscode-buf
        ]);
      userSettings = {
        "workbench.editor.labelFormat" = "short";
        "workbench.tree.indent" = 16;
        "explorer.sortOrder" = "filesFirst";
        "explorer.compactFolders" = false;
        "editor.fontFamily" = "Fira Code";
        "editor.fontLigatures" = true;
        "svelte.enable-ts-plugin" = true;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.formatterPath" = "alejandra";
      };
    };
    mutableExtensionsDir = false;
  };

  catppuccin.vscode = {
    enable = true;
    accent = "sky";
    flavor = "mocha";
  };

  # Required packages
  home.packages = with pkgs; [
    nixd
    alejandra
  ];
}
