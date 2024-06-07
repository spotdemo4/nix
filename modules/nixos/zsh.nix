{ lib, config, pkgs, ... }:
 
{
  options.zsh-nix = {
    enable = lib.mkEnableOption "enable zsh";
  };

  config = lib.mkIf config.zsh-nix.enable {
    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };
}