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
        args = [ ];
      };
      context7 = {
        command = "${context7Wrapper}/bin/context7-mcp-wrapper";
        args = [ ];
      };
    };
  };
}
