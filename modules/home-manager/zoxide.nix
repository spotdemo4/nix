{...}: {
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.shellAliases = {
    cd = "zoxide";
  };
}
