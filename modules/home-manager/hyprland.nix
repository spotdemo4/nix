{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # Startup
      exec-once = [
        "nm-applet --indicator"
        "blueman-applet"
        "trevbar"
      ];

      # Env vars
      env = [
        "QT_QPA_PLATFORMTHEME,qt5ct"
      ];

      # Define variables
      "$mod" = "SUPER";
      "$menu" = "wofi --show drun";
      "$terminal" = "konsole";
      "$screenshot" = "grimblast --freeze copy area";

      # Display configuration
      monitor = [
        # Laptop
        "eDP-1,preferred,auto,1"
        "desc:Samsung Electric Company S34J55x H4LT901888,3440x1440@74.98Hz,auto,auto"

        #Desktop
        "desc:GIGA-BYTE TECHNOLOGY CO. LTD. G34WQC A,3440x1440@60,auto,auto"
        "desc:GIGA-BYTE TECHNOLOGY CO. LTD. G34WQC A 23072B001686,3440x1440@144,auto,auto"
        "desc:Dell Inc. S2719DGF 1HSYBY2,2560x1440@60,auto,auto,transform,1"

        ",preferred,auto,auto"
      ];

      workspace = "m[desc:Dell Inc. S2719DGF 1HSYBY2], layoutopt:orientation:top";

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
      };

      misc = {
        "force_default_wallpaper" = 0;
      };

      #Keyboard config
      input = {
        "kb_layout" = "us";
        "follow_mouse" = 1;
      };

      # Group config
      group = {
        "col.border_active" = "rgba(ff9900ee) rgba(ff1a00ee) 45deg";
        "col.border_inactive" = "rgba(595959aa)";

        groupbar = {
          "enabled" = false;
          "font_size" = 14;
          "col.active" = "rgba(1e1e2eee)";
          "col.inactive" = "rgba(11111bee)";
        };
      };

      # Bind config
      binds = {
        "scroll_event_delay" = 100;
      };

      #Keyboard binds
      bind = [
        "$mod, C, killactive,"
        "$mod, SPACE, exec, $menu"
        "$mod, V, togglefloating,"
        "$mod, G, layoutmsg, swapwithmaster"
        "$mod, S, exec, $screenshot"
        "$mod, T, togglegroup"

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

        # Scroll through group
        "$mod, mouse_down, changegroupactive, b"
        "$mod, mouse_up, changegroupactive, f"

        # Change brightness
        ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ",XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };

  home.packages = with pkgs; [
    brightnessctl
  ];
}
