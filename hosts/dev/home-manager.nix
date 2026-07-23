{
  config,
  inputs,
  pkgs,
  self,
  ...
}:
let
  tmuxCommandPicker = pkgs.writeShellApplication {
    name = "tmux-command-picker";
    runtimeInputs = [
      pkgs.fzf
      pkgs.tmux
    ];
    text = builtins.readFile ./tmux-command-picker.sh;
  };
  tmuxSessionPicker = pkgs.writeShellApplication {
    name = "tmux-session-picker";
    runtimeInputs = [
      pkgs.fzf
      pkgs.tmux
    ];
    text = builtins.readFile ./tmux-session-picker.sh;
  };
in
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.agenix.homeManagerModules.default
    (self + /modules/home-manager/codex)
    (self + /modules/home-manager/gpg)
    (self + /modules/home-manager/mcp)
    (self + /modules/home-manager/opencode)
    (self + /modules/home-manager/ssh)
  ];

  home = {
    username = "trev";
    homeDirectory = "/home/trev";
    stateVersion = "24.05";
    packages = [
      tmuxCommandPicker
      tmuxSessionPicker
    ];
    sessionVariables.NIX_PATH = "nixpkgs=${inputs.nixpkgs.outPath}";
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
    tmux = {
      enable = true;
      baseIndex = 1;
      escapeTime = 0;
      extraConfig = ''
        set -g allow-passthrough on
        set -s extended-keys on
        set -s extended-keys-format csi-u
        set -s terminal-features[100] 'xterm*:extkeys'
        unbind-key -nq C-S-p
        bind-key -n -N "Search and run key bindings (Ctrl-Shift-P)" C-F12 \
          set-environment -gF TMUX_COMMAND_PICKER_CLIENT "#{client_name}" \; \
          display-popup -E -w 80% -h 80% -T " tmux commands " \
          "${tmuxCommandPicker}/bin/tmux-command-picker" \; \
          set-environment -gu TMUX_COMMAND_PICKER_CLIENT
      '';
      historyLimit = 100000;
      mouse = true;
      terminal = "tmux-256color";
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      loginExtra = ''
        if [[ -n "$SSH_CONNECTION" && -t 0 ]]; then
          export GPG_TTY="$(tty)"
          gpg-connect-agent updatestartuptty /bye >/dev/null

          if ! gpg-connect-agent "KEYINFO 02F9D60E16452DC74C0FBFC2ECA9E20D1D75C89C" /bye 2>/dev/null \
            | grep -q '^S KEYINFO 02F9D60E16452DC74C0FBFC2ECA9E20D1D75C89C [^ ]* [^ ]* [^ ]* 1 '; then
            print -n | gpg --quiet --yes --local-user 3AAF87E0B1A2AC36 --detach-sign --output /dev/null
          fi

          if [[ -z "$TMUX" && "$PWD" == "$HOME" ]]; then
            "${tmuxSessionPicker}/bin/tmux-session-picker"
          fi
        fi
      '';
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
    tmux = {
      enable = true;
      flavor = "mocha";
    };
  };

  trev = {
    mcp = {
      enable = true;
      chromeHeadless = true;
    };
    programs = {
      codex.enable = true;
      gpg.enable = true;
      opencode.enable = true;
      ssh = {
        enable = true;
        proxyJump = null;
      };
    };
  };

  xdg.configFile."tmux/tmux.conf".onChange = ''
    export TMUX_TMPDIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    if ${pkgs.tmux}/bin/tmux has-session 2>/dev/null; then
      ${pkgs.tmux}/bin/tmux source-file "${config.xdg.configHome}/tmux/tmux.conf"
    fi
  '';

  # https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;
}
