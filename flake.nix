{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Use Lix https://lix.systems/
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.1-1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen browser
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # Catppuccin
    catppuccin.url = "github:catppuccin/nix";
    catppuccin-vsc.url = "https://flakehub.com/f/catppuccin/vscode/*.tar.gz";

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
    lix-module,
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
          lix-module.nixosModules.default
        ];
      };

      desktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/desktop/configuration.nix
          lix-module.nixosModules.default
        ];
      };

      server = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/server/configuration.nix
          lix-module.nixosModules.default
        ];
      };
    };

    formatter = forSystem ({pkgs, ...}: pkgs.alejandra);
  };
}
