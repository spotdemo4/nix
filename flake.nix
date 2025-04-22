{
  description = "Trev's config flake";

  nixConfig = {
    extra-substituters = [
      "https://trix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "trix.cachix.org-1:uZzPf9A0ij1eIlDn9jg7fZyxUGfbZrcRujVMIG6apVA="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Zen browser
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # Catppuccin
    catppuccin.url = "github:catppuccin/nix";

    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix vscode extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # Filebrowser-upload
    filebrowser-upload.url = "github:spotdemo4/filebrowser-upload";

    # Trevbar
    trevbar.url = "github:spotdemo4/trevbar";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    build-systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forSystem = f:
      nixpkgs.lib.genAttrs build-systems (
        system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
            };
          }
      );
  in {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/laptop/configuration.nix
        ];
      };

      desktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/desktop/configuration.nix
        ];
      };

      server = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/server/configuration.nix
        ];
      };
    };

    checks = forSystem ({pkgs, ...}: {
      nix = with pkgs;
        runCommandLocal "check-nix" {
          nativeBuildInputs = with pkgs; [
            alejandra
          ];
        } ''
          cd ${./.}
          alejandra -c .
          touch $out
        '';
    });

    formatter = forSystem ({pkgs, ...}: pkgs.alejandra);
  };
}
