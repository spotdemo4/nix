{
  description = "Trev's config flake";

  nixConfig = {
    extra-substituters = [
      "https://trix.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "trix.cachix.org-1:uZzPf9A0ij1eIlDn9jg7fZyxUGfbZrcRujVMIG6apVA="
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

    # Quick Commit
    quick-commit = {
      url = "github:spotdemo4/quick-commit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Quadlet-nix
    quadlet-nix.url = "github:spotdemo4/quadlet-nix";
  };

  outputs = {
    self,
    nixpkgs,
    nur,
    agenix,
    quadlet-nix,
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
            nur.modules.nixos.default
            ./hosts/desktop/configuration.nix
          ];
        };
      }
      // servers;

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
