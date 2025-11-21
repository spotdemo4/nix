{
  pkgs,
  inputs,
  ...
}:
{
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
        ++ (inputs.nix4vscode.lib."${pkgs.stdenv.hostPlatform.system}".forVscodeVersion
          pkgs.vscodium.version
          [
            "biomejs.biome"
            "bradlc.vscode-tailwindcss"
            "bufbuild.vscode-buf"
            "dbaeumer.vscode-eslint"
            "esbenp.prettier-vscode"
            "github.copilot-chat"
            "github.copilot"
            "mkhl.direnv"
            "svelte.svelte-vscode"
            "tamasfe.even-better-toml"
          ]
        )
        ++ (inputs.nix4vscode.lib."${pkgs.stdenv.hostPlatform.system}".forOpenVsxVersion
          pkgs.vscodium.version
          [
            "sqlfluff.vscode-sqlfluff"
          ]
        );
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
