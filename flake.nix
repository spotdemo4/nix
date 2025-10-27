{
  description = "Trev's config flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.trev.zip/nixos"
      "https://cache.trev.zip/nur"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos:jjDrT2JC8pbKe14eKmsSKgnNHdGtSk3yqbqxFVRx0MY="
      "nur:70xGHUW1+1b8FqBchldaunN//pZNVo6FKuPL4U/n844="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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

    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Nix vscode extensions
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix user repository
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Quadlet-nix
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    # Trevbar
    trevbar = {
      url = "github:spotdemo4/trevbar";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nur.follows = "nur";
    };
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
          alejandra
          (pkgs.writeShellApplication {
            name = "secret";
            runtimeInputs = [agenix];
            text = ''
              EDITOR="nano -L" agenix -e "$@"
            '';
          })

          # Actions
          nix-fast-build
          flake-checker
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
            action-validator .github/**/*.yaml
            renovate-config-validator .github/renovate.json
          '';
        };
      }
      // {
        shell = devShells."${system}".default;
      });

    formatter = forSystem ({pkgs, ...}: pkgs.alejandra);
  };
}
