{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  secretFiles = {
    context7 = self + /secrets/context7.age;
    forgejo-mcp = self + /secrets/forgejo-mcp.age;
    github = self + /secrets/github.age;
    kagi = self + /secrets/kagi.age;
  };
  secretPath = name: config.trev.mcp.secretPaths.${name} or config.age.secrets.${name}.path;
  chromeDevtoolsArgs = [
    "--no-usage-statistics"
    "--executable-path=${pkgs.chromium}/bin/chromium"
  ]
  ++ lib.optional config.trev.mcp.chromeHeadless "--headless=true";
  kagiWrapper = pkgs.writeShellApplication {
    name = "kagi-mcp-wrapper";
    runtimeInputs = with pkgs; [ trev.kagimcp ];
    text = ''
      KAGI_API_KEY="$(cat "${secretPath "kagi"}")"
      export KAGI_API_KEY
      exec kagimcp "$@"
    '';
  };
  githubWrapper = pkgs.writeShellApplication {
    name = "github-mcp-wrapper";
    runtimeInputs = with pkgs; [ github-mcp-server ];
    text = ''
      GITHUB_PERSONAL_ACCESS_TOKEN="$(cat "${secretPath "github"}")"
      export GITHUB_PERSONAL_ACCESS_TOKEN
      exec github-mcp-server "$@"
    '';
  };
  context7Wrapper = pkgs.writeShellApplication {
    name = "context7-mcp-wrapper";
    runtimeInputs = with pkgs; [ context7-mcp ];
    text = ''
      CONTEXT7_API_KEY="$(cat "${secretPath "context7"}")"
      export CONTEXT7_API_KEY
      exec context7-mcp "$@"
    '';
  };
  chromeDevtoolsWrapper = pkgs.writeShellApplication {
    name = "chrome-devtools-mcp-wrapper";
    text = ''
      exec ${pkgs.trev.chrome-devtools-mcp}/bin/chrome-devtools-mcp ${lib.escapeShellArgs chromeDevtoolsArgs} "$@"
    '';
  };
  forgejoWrapper = pkgs.writeShellApplication {
    name = "forgejo-mcp-wrapper";
    runtimeInputs = with pkgs; [ forgejo-mcp ];
    text = ''
      FORGEJO_ACCESS_TOKEN="$(cat "${secretPath "forgejo-mcp"}")"
      FORGEJO_URL="https://trev.zip"
      export FORGEJO_ACCESS_TOKEN FORGEJO_URL
      exec forgejo-mcp "$@"
    '';
  };
in
{
  options.trev.mcp = {
    secretPaths = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Externally decrypted MCP secret paths";
    };

    chromeHeadless = lib.mkEnableOption "headless Chrome for the Chrome DevTools MCP server";
  };

  config = {
    age.secrets = lib.mapAttrs (_: file: { inherit file; }) (
      lib.filterAttrs (name: _: !(builtins.hasAttr name config.trev.mcp.secretPaths)) secretFiles
    );

    programs.mcp = {
      enable = true;
      servers = {
        kagi = {
          command = "${kagiWrapper}/bin/kagi-mcp-wrapper";
          args = [ ];
        };
        github = {
          command = "${githubWrapper}/bin/github-mcp-wrapper";
          args = [ "stdio" ];
        };
        context7 = {
          command = "${context7Wrapper}/bin/context7-mcp-wrapper";
          args = [ ];
        };
        chrome-devtools = {
          command = "${pkgs.trev.chrome-devtools-mcp}/bin/chrome-devtools-mcp";
          args = chromeDevtoolsArgs;
        };
        forgejo = {
          command = "${forgejoWrapper}/bin/forgejo-mcp-wrapper";
          args = [ "--transport=stdio" ];
        };
      };
    };

    home.file = {
      ".local/bin/kagi-mcp-wrapper".source = "${kagiWrapper}/bin/kagi-mcp-wrapper";
      ".local/bin/github-mcp-wrapper".source = "${githubWrapper}/bin/github-mcp-wrapper";
      ".local/bin/context7-mcp-wrapper".source = "${context7Wrapper}/bin/context7-mcp-wrapper";
      ".local/bin/chrome-devtools-mcp-wrapper".source =
        "${chromeDevtoolsWrapper}/bin/chrome-devtools-mcp-wrapper";
      ".local/bin/forgejo-mcp-wrapper".source = "${forgejoWrapper}/bin/forgejo-mcp-wrapper";
    };
  };
}
