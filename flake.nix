{
  description = "Trev's config flake";

  nixConfig = {
    extra-substituters = [
      "https://trix.cachix.org"
      "https://trevnur.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "trix.cachix.org-1:uZzPf9A0ij1eIlDn9jg7fZyxUGfbZrcRujVMIG6apVA="
      "trevnur.cachix.org-1:hBd15IdszwT52aOxdKs5vNTbq36emvEeGqpb25Bkq6o="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Zen browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Agenix
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix vscode extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix user repository
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Filebrowser-upload
    filebrowser-upload = {
      url = "github:spotdemo4/filebrowser-upload";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Trevbar
    trevbar = {
      url = "github:spotdemo4/trevbar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Quadlet-nix
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
  };

  outputs = {
    self,
    nixpkgs,
    agenix,
    catppuccin,
    home-manager,
    nur,
    quadlet-nix,
    ...
  } @ inputs: let
    build-systems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forSystem = f:
      nixpkgs.lib.genAttrs build-systems (
        system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
              overlays = [nur.overlays.default];
            };
          }
      );

    servers =
      nixpkgs.lib.mapAttrs' (
        name: value:
          nixpkgs.lib.nameValuePair
          (nixpkgs.lib.removeSuffix ".nix" name)
          (nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs self;
              hostname = nixpkgs.lib.removeSuffix ".nix" name;
            };
            modules = [
              agenix.nixosModules.default
              catppuccin.nixosModules.catppuccin
              home-manager.nixosModules.home-manager
              quadlet-nix.nixosModules.quadlet
              ./servers/${name}
            ];
          })
      )
      (builtins.readDir ./servers);
  in {
    nixosConfigurations =
      {
        laptop = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs self;
            hostname = "laptop";
          };
          modules = [
            agenix.nixosModules.default
            catppuccin.nixosModules.catppuccin
            home-manager.nixosModules.home-manager
            nur.modules.nixos.default
            ./hosts/laptop/configuration.nix
          ];
        };

        desktop = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs self;
            hostname = "desktop";
          };
          modules = [
            agenix.nixosModules.default
            catppuccin.nixosModules.catppuccin
            home-manager.nixosModules.home-manager
            nur.modules.nixos.default
            ./hosts/desktop/configuration.nix
          ];
        };

        htpc = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs self;
            hostname = "htpc";
          };
          modules = [
            agenix.nixosModules.default
            catppuccin.nixosModules.catppuccin
            home-manager.nixosModules.home-manager
            nur.modules.nixos.default
            ./hosts/htpc/configuration.nix
          ];
        };
      }
      // servers;

    devShells = forSystem ({pkgs, ...}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          git
          nix-update
          alejandra
          prettier
          renovate
        ];
      };
    });

    checks = forSystem ({pkgs, ...}:
      pkgs.nur.repos.trev.lib.mkChecks {
        lint = {
          src = ./.;
          nativeBuildInputs = with pkgs; [
            alejandra
            prettier
          ];
          checkPhase = ''
            alejandra -c .
            prettier --check .
          '';
        };
      });

    formatter = forSystem ({pkgs, ...}: pkgs.alejandra);
  };
}
