{ config, lib, pkgs, ... }:

{
  # age.secrets.vllm-api = {
  #   file = ../../secrets/vllm-api.age;
  #   path = config.home.homeDirectory + "/.secrets";
  # };

  # home.activation = {
  #   continue = lib.hm.dag.entryAfter ["installPackages"] ''
  #     secret=$(cat "${config.age.secrets.vllm-api.path}")
  #     configFile=$HOME/.continue/config.json
  #     ${pkgs.gnused}/bin/sed -i "s#@vllm-api-key@#$secret#" "$configFile"
  #   '';
  # };

  # home.activation = {
  #   continue = lib.hm.dag.entryAfter ["installPackages"] ''
  #     secret=$(cat "${config.age.secrets.vllm-api.path}")
  #     echo $secret
  #   '';
  # };

  # system.activationScripts."vllm-api-key-secret" = ''
  #   secret=$(cat "${config.age.secrets.vllm-api.path}")
  #   configFile=$HOME/.continue/config.json
  #   ${pkgs.gnused}/bin/sed -i "s#@vllm-api-key@#$secret#" "$configFile"
  # '';

  home.file = {
    ".continue/config.json".text = ''
      {
        "models": [
          {
            "model": "AUTODETECT",
            "title": "vLLM",
            "completionOptions": {},
            "apiBase": "http://main:8000/v1",
            "apiKey": "",
            "provider": "openai"
          }
        ],
        "tabAutocompleteModel": {
          "title": "Qwen2.5-Coder",
          "provider": "openai",
          "apiBase": "http://main:8000/v1",
          "apiKey": "@vllm-api-key@",
          "model": "Qwen/Qwen2.5-Coder-7B"
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
