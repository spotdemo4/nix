{
  pkgs,
  inputs,
  ...
}:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;
    profiles.default = {
      extensions =
        (inputs.nix4vscode.lib."${pkgs.stdenv.hostPlatform.system}".forVscodeVersion pkgs.vscode.version [
          "github.copilot-chat"
        ])
        ++ (inputs.nix4vscode.lib."${pkgs.stdenv.hostPlatform.system}".forOpenVsxVersion pkgs.vscode.version
          [
            "a-h.templ"
            "anthropic.claude-code"
            "biomejs.biome"
            "bradlc.vscode-tailwindcss"
            "bufbuild.vscode-buf"
            "charliermarsh.ruff"
            "dbaeumer.vscode-eslint"
            "esbenp.prettier-vscode"
            "gleam.gleam"
            "golang.Go"
            "jnoortheen.nix-ide"
            "llvm-vs-code-extensions.vscode-clangd"
            "mkhl.direnv"
            "ms-python.python"
            "openai.chatgpt"
            "redhat.vscode-yaml"
            "ReneSaarsoo.sql-formatter-vsc"
            "rust-lang.rust-analyzer"
            "sqlfluff.vscode-sqlfluff"
            "svelte.svelte-vscode"
            "timonwong.shellcheck"
            "tombi-toml.tombi"
            "usernamehw.errorlens"
            "ziglang.vscode-zig"
          ]
        );
      userSettings = {
        "telemetry.telemetryLevel" = "off";
        "workbench.editor.labelFormat" = "short";
        "workbench.editor.showTabs" = "none";
        "workbench.tree.indent" = 16;
        "explorer.sortOrder" = "filesFirst";
        "explorer.compactFolders" = false;
        "editor.fontFamily" = "Fira Code";
        "editor.fontLigatures" = true;
        "editor.minimap.enabled" = false;
        "chat.viewSessions.orientation" = "stacked";

        "json.schemaDownload.trustedDomains" = {
          # defaults
          "https://schemastore.azurewebsites.net/" = true;
          "https://raw.githubusercontent.com/" = true;
          "https://www.schemastore.org/" = true;
          "https://json.schemastore.org/" = true;
          "https://json-schema.org/" = true;

          # https://github.com/catppuccin/vscode/issues/632
          "https://esm.sh/" = true;

          # biomejs.biome
          "https://biomejs.dev" = true;
        };

        # https://github.com/microsoft/vscode/issues/237819#issuecomment-3265147980
        "chat.disableAIFeatures" = false;

        # jnoortheen.nix-ide
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        # https://github.com/nix-community/vscode-nix-ide/issues/482
        "nix.hiddenLanguageServerErrors" = [
          "textDocument/definition"
        ];

        # biomejs.biome
        "biome.enabled" = false;

        # redhat.vscode-yaml
        "redhat.telemetry.enabled" = false;

        # svelte.svelte-vscode
        "svelte.enable-ts-plugin" = true;

        # zigland.vscode-zig
        "zig.zls.enabled" = "on";
      };
    };
  };

  catppuccin.vscode.profiles.default = {
    enable = true;
    accent = "sky";
    flavor = "mocha";

    icons = {
      enable = true;
      flavor = "mocha";
    };
  };

  # Required packages
  home.packages = with pkgs; [
    biome
    nixd
    nixfmt
    sqlfluff
  ];
}
