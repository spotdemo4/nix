{ inputs, ... }:
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.agenix.homeManagerModules.default
  ];

  home = {
    username = "trev";
    homeDirectory = "/home/trev";
    stateVersion = "24.05";
    shellAliases = {
      cd = "z";
      docker = "podman --url unix:///run/podman/podman.sock";
      logs = "journalctl -b -e -u";
      ls = "eza";
      top = "btop";
    };
  };

  programs = {
    bat.enable = true;
    btop.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
      silent = true;
    };
    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    home-manager.enable = true;
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        container.disabled = true;
        command_timeout = 3600000;
      };
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
    };
  };

  catppuccin = {
    enable = true;
    autoEnable = false;
    bat = {
      enable = true;
      flavor = "mocha";
    };
    btop = {
      enable = true;
      flavor = "mocha";
    };
    fzf = {
      enable = true;
      flavor = "mocha";
    };
    starship = {
      enable = true;
      flavor = "mocha";
    };
  };

  # https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;
}
