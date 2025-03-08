{ config, lib, pkgs, ... }:

{
  home.file = {
    ".continue/config.json".text = ''
      {
        "models": [
          {
            "model": "AUTODETECT",
            "title": "vLLM",
            "provider": "openai",
            "completionOptions": {},
            "apiBase": "http://main:8080/v1",
          }
        ],
        "tabAutocompleteModel": {
          "model": "Qwen/Qwen2.5-Coder-7B",
          "title": "Qwen2.5-Coder",
          "provider": "openai",
          "apiBase": "http://main:8080/v1",
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
