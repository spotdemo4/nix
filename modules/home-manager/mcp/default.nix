{
  self,
  config,
  pkgs,
  ...
}:
let
  kagiWrapper = pkgs.writeShellApplication {
    name = "kagi-mcp-wrapper";
    runtimeInputs = with pkgs; [ trev.kagimcp ];
    text = ''
      KAGI_API_KEY="$(cat "${config.age.secrets."kagi".path}")"
      export KAGI_API_KEY
      exec kagimcp "$@"
    '';
  };
  githubWrapper = pkgs.writeShellApplication {
    name = "github-mcp-wrapper";
    runtimeInputs = with pkgs; [ github-mcp-server ];
    text = ''
      GITHUB_PERSONAL_ACCESS_TOKEN="$(cat "${config.age.secrets."github".path}")"
      export GITHUB_PERSONAL_ACCESS_TOKEN
      exec github-mcp-server "$@"
    '';
  };
  context7Wrapper = pkgs.writeShellApplication {
    name = "context7-mcp-wrapper";
    runtimeInputs = with pkgs; [ context7-mcp ];
    text = ''
      CONTEXT7_API_KEY="$(cat "${config.age.secrets."context7".path}")"
      export CONTEXT7_API_KEY
      exec context7-mcp "$@"
    '';
  };
  chromeDevtoolsWrapper = pkgs.writeShellApplication {
    name = "chrome-devtools-mcp-wrapper";
    text = ''
      exec ${pkgs.trev.chrome-devtools-mcp}/bin/chrome-devtools-mcp \
        --no-usage-statistics \
        --executable-path=${pkgs.chromium}/bin/chromium \
        "$@"
    '';
  };
  forgejoWrapper = pkgs.writeShellApplication {
    name = "forgejo-mcp-wrapper";
    runtimeInputs = with pkgs; [ forgejo-mcp ];
    text = ''
      FORGEJO_ACCESS_TOKEN="$(cat "${config.age.secrets."forgejo-mcp".path}")"
      FORGEJO_URL="https://trev.zip"
      export FORGEJO_ACCESS_TOKEN FORGEJO_URL
      exec forgejo-mcp "$@"
    '';
  };
in
{
  age.secrets."kagi".file = self + /secrets/kagi.age;
  age.secrets."github".file = self + /secrets/github.age;
  age.secrets."context7".file = self + /secrets/context7.age;

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
        args = [
          "--no-usage-statistics"
          "--executable-path=${pkgs.chromium}/bin/chromium"
        ];
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
}
