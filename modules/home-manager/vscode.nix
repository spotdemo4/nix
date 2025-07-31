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
        ++ (inputs.nix4vscode.lib."${pkgs.system}".forVscodeVersion pkgs.vscodium.version [
          "anthropic.claude-code"
          "bradlc.vscode-tailwindcss"
          "bufbuild.vscode-buf"
          "dbaeumer.vscode-eslint"
          "dorzey.vscode-sqlfluff"
          "esbenp.prettier-vscode"
          "github.copilot-chat"
          "github.copilot"
          "kamadorueda.alejandra"
          "svelte.svelte-vscode"
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

        # https://github.com/nix-community/vscode-nix-ide/issues/482
        "nix.hiddenLanguageServerErrors" = [
          "textDocument/definition"
        ];
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
