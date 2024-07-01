{ lib, config, ... }:
 
{
  options.hyprland-conf = {
    enable = lib.mkEnableOption "enable hyprland config";
  };

  config = lib.mkIf config.hyprland-conf.enable {
    wayland.windowManager.hyprland = {
      enable = true;
    
      settings = {
        # Startup
        exec-once = [
          "nm-applet --indicator"
          "blueman-applet"
          "waybar"
          "hyprpaper"
        ];

        # Env vars
        env = [
          #"HYPRCURSOR_THEME,catppuccin-mocha-dark-cursors"
          #"HYPRCURSOR_SIZE,22"
          "QT_QPA_PLATFORMTHEME,qt5ct"
        ];

        # Define variables
        "$mod" = "SUPER";      
        "$menu" = "wofi --show drun";
        "$terminal" = "konsole";
        "$screenshot" = "grimblast copy area";

        # Display configuration
        monitor = [
          "eDP-1,preferred,auto,1"
          ",preferred,auto,auto"
        ];

        general = {
          "gaps_in" = 5;
          "gaps_out" = 20;
          "border_size" = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          "layout" = "master";
          "allow_tearing" = false;
        };

        decoration = {
          "rounding" = 10;
          "drop_shadow" = "yes";
          "shadow_range" = 4;
          "shadow_render_power" = 3;
          "col.shadow" = "rgba(1a1a1aee)";

          blur = {
            "enabled" = true;
            "size" = 3;
            "passes" = 1;
          };
        };

        animations = {
          "enabled" = true;
          "bezier" = "myBezier, 0.05, 0.9, 0.1, 1.05";

          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        dwindle = {
          "pseudotile" = "yes";
          "preserve_split" = "yes";
        };

        master = {
          "mfact" = "0.5";
          "new_on_top" = true;
        };

        gestures = {
          "workspace_swipe" = "off";
        };

        misc = {
          "force_default_wallpaper" = 0;
        };          

        #Keyboard config
        input = {
          "kb_layout" = "us";
          "follow_mouse" = 1;
        };

        #Keyboard binds
        bind = [
          "$mod, C, killactive,"
          "$mod, SPACE, exec, $menu"
          "$mod, V, togglefloating,"
          "$mod, G, layoutmsg, swapwithmaster"
          "$mod, S, exec, $screenshot"

          # Switch workspace with mainMod + [0-9]
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"

          # Move active window to workspace with mod + SHIFT + [0-9]
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"

          # Cycle through workspaces
          "$mod SHIFT, left, workspace, r-1"
          "$mod SHIFT, right, workspace, r+1"

          # Scroll through workspaces
          "$mod, mouse_down, workspace, e-1"
          "$mod, mouse_up, workspace, e+1"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
      };
    };
  };
}
