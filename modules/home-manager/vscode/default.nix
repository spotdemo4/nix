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
      extensions = (
        inputs.nix4vscode.lib."${pkgs.stdenv.hostPlatform.system}".forVscodeVersion pkgs.vscode.version [
          "a-h.templ"
          "anthropic.claude-code"
          "biomejs.biome"
          "bradlc.vscode-tailwindcss"
          "bufbuild.vscode-buf"
          "charliermarsh.ruff"
          "dbaeumer.vscode-eslint"
          "esbenp.prettier-vscode"
          "github.copilot-chat"
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
        ++ [
          pkgs.trev.oxc-vscode
        ]
      );
      userSettings = pkgs.lib.importJSON ./settings.json;
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
