{ lib, config, pkgs, ... }:
 
{
  options.waybar-conf = {
    enable = lib.mkEnableOption "enable waybar config";
  };

  config = lib.mkIf config.waybar-conf.enable {
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          height = 24;
          modules-left = [
            "hyprland/workspaces"
            "hyprland/submap"
          ];
          modules-center = [
            "hyprland/window"
          ];
          modules-right = [
            "idle_inhibitor"
            "temperature"
            "cpu"
            "memory"
            "network"
            "pulseaudio"
            "backlight"
            "keyboard-state"
            "battery"
            "tray"
            "clock"
          ];

          "keyboard-state" = {
            "numlock" = true;
            "capslock" = true;
            "format" = "{name}";
          };

          "idle_inhibitor" = {
            "format" = "{icon}";
            "format-icons" = {
              "activated" = "";
              "deactivated" = "";
            };
          };

          "tray" = {
            "spacing" = 10;
          };

          "clock" = {
            "format" = "{:%I:%M}";
            "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            "format-alt" = "{:%Y-%m-%d}";
          };

          "cpu" = {
            "format" = " {usage}%";
          };

          "memory" = {
            "format" = " {}%";
          };

          "temperature" = {
            "thermal-zone" = 2;
            "hwmon-path" = "/sys/class/hwmon/hwmon1/temp1_input";
            "critical-threshold" = 80;
            "format-critical" = "{temperatureC}°C";
            "format" = "{temperatureC}°C";
          };

          "backlight" = {
            "format" = "{icon} {percent}%";
            "format-icons" = [
              ""
              ""
              ""
              ""
              ""
              ""
              ""
              ""
              ""
            ];
          };

          "battery" = {
            "states" = {
              "warning" = 30;
              "critical" = 15;
            };
            "format" = "{icon} {capacity}%"; 
            "format-charging" = "🔌 {capacity}%";
            "format-plugged" = " {capacity}%";
          };

          "network" = {
            "format-wifi" = "{essid} ({signalStrength}%) ";
            "format-ethernet" = " {ifname}";
            "tooltip-format" = " {ifname} via {gwaddr}";
            "format-linked" = " {ifname} (No IP)";
            "format-disconnected" = "Disconnected ⚠ {ifname}";
            "format-alt" = " {ifname}: {ipaddr}/{cidr}";
          };

          "pulseaudio" = {
            "format" = "{icon} {volume}% {format_source}";
            "format-bluetooth" = " {icon} {volume}% {format_source}";
            "format-bluetooth-muted" = "  {icon} {format_source}";
            "format-muted" = "  {format_source}";
            "format-source" = " {volume}%";
            "format-source-muted" = "";
            "format-icons" = {
              "default" = ["" "" ""];
            };
            "on-click" = "pavucontrol";
          };
        };
      };

      style = ''
      * {
        /* `otf-font-awesome` is required to be installed for icons */
        font-family: "Noto Sans CJK KR Regular";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        /*    background-color: rgba(43, 48, 59, 0.5); */
        /*    border-bottom: 3px solid rgba(100, 114, 125, 0.5); */
        color: #ffffff;
        transition-property: background-color;
        transition-duration: .5s;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      #waybar.empty #window {
        background-color: transparent;
      }

      #window {
        margin: 2;
        padding-left: 8;
        padding-right: 8;
        background-color: rgba(0,0,0,0.3);
        font-size:14px;
        font-weight: bold;
      }

      button {
        /* Use box-shadow instead of border so the text isn't offset */
        box-shadow: inset 0 -3px transparent;
        /* Avoid rounded borders under each button name */
        border: none;
        border-radius: 0;
      }

      /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
      button:hover {
        background: inherit;
        border-top: 2px solid #89dceb;
      }

      #workspaces button {
        padding: 0 4px;
        color: #ffffff;
      }

      #workspaces button.active {
        background-color: rgba(0,0,0,0.3);
        border-top: 2px solid #89dceb;
      }

      #workspaces button.focused {
        background-color: rgba(0,0,0,0.3);
        border-top: 2px solid #89dceb;
      }

      #workspaces button.urgent {
        background-color: #eb4d4b;
      }

      #mode {
        background-color: #64727D;
        border-bottom: 3px solid #ffffff;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #wireplumber,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad,
      #mpd {
        margin: 2px;
        padding-left: 4px;
        padding-right: 4px;
        background-color: rgba(0,0,0,0.3);
        color: #ffffff;
      }

      /* If workspaces is the leftmost module, omit left margin */
      .modules-left > widget:first-child > #workspaces {
        margin-left: 0;
      }

      /* If workspaces is the rightmost module, omit right margin */
      .modules-right > widget:last-child > #workspaces {
        margin-right: 0;
      }

      #clock {
        font-size:14px;
        font-weight: bold;
      }

      #battery icon {
        color: red;
      }

      #battery.charging, #battery.plugged {
        color: #ffffff;
        background-color: #26A65B;
      }

      @keyframes blink {
        to {
          background-color: #ffffff;
          color: #000000;
        }
      }

      #battery.warning:not(.charging) {
        background-color: #f53c3c;
        color: #ffffff;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #battery.critical:not(.charging) {
        background-color: #f53c3c;
        color: #ffffff;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      label:focus {
        background-color: #000000;
      }

      #network.disconnected {
        background-color: #f53c3c;
      }

      #temperature.critical {
        background-color: #eb4d4b;
      }

      #idle_inhibitor.activated {
        background-color: #ecf0f1;
        color: #2d3436;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #eb4d4b;
      }
      '';
    };
  };
}
