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
    # filebrowser-upload = {
    #   url = "github:spotdemo4/filebrowser-upload";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Trevbar
    trevbar = {
      url = "github:spotdemo4/trevbar";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nur.follows = "nur";
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
              config.allowUnfree = true;
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
  in rec {
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
          pkgs.nur.repos.trev.renovate
        ];
        shellHook = pkgs.nur.repos.trev.shellhook.ref;
      };
    });

    checks = forSystem ({
      pkgs,
      system,
      ...
    }:
      pkgs.nur.repos.trev.lib.mkChecks {
        lint = {
          src = ./.;
          deps = with pkgs; [
            alejandra
            prettier
            action-validator
            pkgs.nur.repos.trev.renovate
          ];
          script = ''
            alejandra -c .
            prettier --check .
            renovate-config-validator
            action-validator .github/workflows/*
          '';
        };
      }
      // {
        shell = devShells."${system}".default;
      });

    formatter = forSystem ({pkgs, ...}: pkgs.alejandra);
  };
}
