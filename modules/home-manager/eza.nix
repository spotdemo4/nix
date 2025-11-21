{ ... }:
{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
  };

  home.shellAliases = {
    ls = "eza";
  };
}
