{ lib, config, pkgs, ... }:
 
{
  options.update-script = {
    enable = lib.mkEnableOption "enable update script";
  };

  config = lib.mkIf config.update-script.enable {
    environment.systemPackages = with pkgs; [
      (writeShellApplication {
        name = "update";

        runtimeInputs = with pkgs; [ git ];

        text = ''
          pushd /etc/nixos
          echo "NixOS Rebuilding..."
          sudo git add .

          sudo nix flake update
          sudo nixos-rebuild switch --flake /etc/nixos#default
          gen=$(nixos-rebuild list-generations | grep current)

          sudo git commit -m "$gen"
          sudo git push -u origin main

          popd
        '';
      })
    ];
  };
}