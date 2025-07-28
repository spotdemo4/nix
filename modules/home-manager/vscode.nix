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
          charliermarsh.ruff
          golang.go
          jnoortheen.nix-ide
          ms-python.python
          usernamehw.errorlens
        ])
        ++ (with inputs.nix-vscode-extensions.extensions.x86_64-linux; [
          vscode-marketplace.bradlc.vscode-tailwindcss
          vscode-marketplace.bufbuild.vscode-buf
          vscode-marketplace.continue.continue
          vscode-marketplace.dbaeumer.vscode-eslint
          vscode-marketplace.dorzey.vscode-sqlfluff
          vscode-marketplace.esbenp.prettier-vscode
          vscode-marketplace.github.copilot
          vscode-marketplace.kamadorueda.alejandra
          vscode-marketplace.svelte.svelte-vscode
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

  catppuccin.vscode.profiles.default = {
    enable = true;
    accent = "sky";
    flavor = "mocha";
  };

  # Required packages
  home.packages = with pkgs; [
    nixd
    alejandra
    sqlfluff
  ];
}
