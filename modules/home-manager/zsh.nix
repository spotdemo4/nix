{ lib, config, pkgs, ... }:
 
{
  options.zsh-conf = {
    enable = lib.mkEnableOption "enable zsh config";
  };

  config = lib.mkIf config.zsh-conf.enable {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      plugins = [
        { name = "powerlevel10k"; src = pkgs.zsh-powerlevel10k; file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme"; }
      ];
      initExtra = ''
        source ~/.p10k.zsh
      '';

      #promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };
}