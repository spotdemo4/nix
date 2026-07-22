{
  inputs,
  self,
  ...
}:
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.agenix.homeManagerModules.default
    (self + /modules/home-manager/chromium)
    (self + /modules/home-manager/codex)
    (self + /modules/home-manager/continue)
    (self + /modules/home-manager/cursor)
    (self + /modules/home-manager/discord)
    (self + /modules/home-manager/gpg)
    (self + /modules/home-manager/gtk)
    (self + /modules/home-manager/hypridle)
    (self + /modules/home-manager/hyprland)
    (self + /modules/home-manager/hyprlock)
    (self + /modules/home-manager/hyprpaper)
    (self + /modules/home-manager/hyprshutdown)
    (self + /modules/home-manager/mcp)
    (self + /modules/home-manager/mods)
    (self + /modules/home-manager/opencode)
    (self + /modules/home-manager/ssh)
    (self + /modules/home-manager/steam)
    (self + /modules/home-manager/vscode)
    (self + /modules/home-manager/waybar)
    (self + /modules/home-manager/wofi)
    (self + /modules/home-manager/zed)
    (self + /modules/home-manager/zen)
  ];

  home = {
    username = "trev";
    homeDirectory = "/home/trev";
    stateVersion = "24.05";
    sessionVariables.NIX_PATH = "nixpkgs=${inputs.nixpkgs.outPath}";
    shellAliases = {
      cd = "z";
      codium = "code";
      logs = "journalctl -b -e -u";
      ls = "eza";
      qc = "codex-commit";
      temp = "cd $(mktemp -d)";
      top = "btop";
      zed = "zeditor";
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
    ghostty.enable = true;
    home-manager.enable = true;
    kitty = {
      enable = true;
      keybindings = {
        "--allow-fallback=shifted,ascii ctrl+shift+p" = "send_key ctrl+f12";
        "shift+enter" = "send_text all \\x1b[13;2u";
      };
      shellIntegration.enableZshIntegration = true;
      settings.auto_reload_config = -1;
    };
    mpv.enable = true;
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
      initContent = ''
        zopen() {
          zeditor "ssh://dev/~/dev/$1"
        }
      '';
    };
  };

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-radius = 10;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
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
    ghostty = {
      enable = true;
      flavor = "mocha";
    };
    kitty = {
      enable = true;
      flavor = "mocha";
    };
    kvantum = {
      enable = true;
      accent = "sky";
      flavor = "mocha";
    };
    mako = {
      enable = true;
      flavor = "mocha";
    };
    mpv = {
      enable = true;
      accent = "sky";
      flavor = "mocha";
    };
    starship = {
      enable = true;
      flavor = "mocha";
    };
  };

  trev = {
    mcp.enable = true;
    programs = {
      chromium.enable = true;
      codex.enable = true;
      continue.enable = true;
      cursor.enable = true;
      discord.enable = true;
      gpg.enable = true;
      gtk.enable = true;
      hyprland.enable = true;
      hyprlock.enable = true;
      hyprshutdown.enable = true;
      mods.enable = true;
      opencode.enable = true;
      ssh.enable = true;
      steam.enable = true;
      vscode.enable = true;
      waybar.enable = true;
      wofi.enable = true;
      zed.enable = true;
      zen.enable = true;
    };
    services = {
      hypridle.enable = true;
      hyprpaper.enable = true;
    };
  };

  # https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;
}
