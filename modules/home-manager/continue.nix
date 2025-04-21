{
  config,
  lib,
  pkgs,
  ...
}: {
  home.file = {
    ".continue/config.json".text = ''
      {
        "models": [
          {
            "model": "AUTODETECT",
            "title": "Ollama",
            "provider": "ollama",
            "completionOptions": {},
            "apiBase": "http://main:11434",
          }
        ],
        "tabAutocompleteModel": {
          "model": "qwen2.5-coder:3b",
          "title": "Qwen2.5-Coder",
          "provider": "ollama",
          "apiBase": "http://main:11434",
        },
        "contextProviders": [
          {
            "name": "code",
            "params": {}
          },
          {
            "name": "docs",
            "params": {}
          },
          {
            "name": "diff",
            "params": {}
          },
          {
            "name": "terminal",
            "params": {}
          },
          {
            "name": "problems",
            "params": {}
          },
          {
            "name": "folder",
            "params": {}
          },
          {
            "name": "codebase",
            "params": {}
          }
        ],
        "slashCommands": [
          {
            "name": "comment",
            "description": "Write comments for the selected code"
          },
          {
            "name": "share",
            "description": "Export the current chat session to markdown"
          },
          {
            "name": "commit",
            "description": "Generate a git commit message"
          }
        ]
      }
    '';
  };
}
