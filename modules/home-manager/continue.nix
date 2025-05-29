{
  config,
  self,
  ...
}: {
  age.secrets."authelia-env".file = self + /secrets/authelia-env.age;
  age.secrets."authelia-env".path = config.home.homeDirectory + "/.continue/.env";

  home.file = {
    ".continue/config.json".text = ''
      {
        "models": [
          {
            "model": "AUTODETECT",
            "title": "Ollama",
            "provider": "ollama",
            "completionOptions": {},
            "apiBase": "https://ollama.trev.zip",
            "requestOptions": {
              "headers": {
                "Authorization": "Basic ''${{ secrets.token }}"
              }
            }
          }
        ],
        "tabAutocompleteModel": {
          "model": "qwen2.5-coder:3b",
          "title": "Qwen2.5-Coder",
          "provider": "ollama",
          "apiBase": "https://ollama.trev.zip",
          "requestOptions": {
            "headers": {
              "Authorization": "Basic xxx"
            }
          }
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
