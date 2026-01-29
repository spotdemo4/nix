{
  description = "trev's config flake";

  nixConfig = {
    extra-substituters = [
      "https://cache.trev.zip/nixos"
      "https://install.determinate.systems"
      "https://cache.trev.zip/nur"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos:jjDrT2JC8pbKe14eKmsSKgnNHdGtSk3yqbqxFVRx0MY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "nur:70xGHUW1+1b8FqBchldaunN//pZNVo6FKuPL4U/n844="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    systems.url = "github:nix-systems/default-linux";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # quadlet nix
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    # determinate nix
    determinate = {
      url = "github:DeterminateSystems/determinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix user repository
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # catppuccin nix
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix vscode extensions
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
      };
    };

    # trev's repository
    trev = {
      url = "github:spotdemo4/nur";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
      };
    };

    # zen browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # age nix
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # trevbar
    trevbar = {
      url = "github:spotdemo4/trevbar";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
        trev.follows = "trev";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      quadlet-nix,
      determinate,
      home-manager,
      nur,
      catppuccin,
      trev,
      agenix,
      ...
    }@inputs:
    trev.libs.mkFlake (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            trev.overlays.packages
            trev.overlays.libs
            nur.overlays.default
          ];
          config.allowUnfree = true;
        };

        servers = nixpkgs.lib.mapAttrs' (
          name: value:
          nixpkgs.lib.nameValuePair (nixpkgs.lib.removeSuffix ".nix" name) (
            nixpkgs.lib.nixosSystem {
              specialArgs = {
                inherit inputs self;
                hostname = nixpkgs.lib.removeSuffix ".nix" name;
              };
              modules = [
                determinate.nixosModules.default
                agenix.nixosModules.default
                catppuccin.nixosModules.catppuccin
                home-manager.nixosModules.home-manager
                quadlet-nix.nixosModules.quadlet
                ./servers/${name}
              ];
            }
          )
        ) (builtins.readDir ./servers);

        fs = pkgs.lib.fileset;
      in
      {
        nixosConfigurations = {
          laptop = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs self;
              hostname = "laptop";
            };
            modules = [
              determinate.nixosModules.default
              agenix.nixosModules.default
              catppuccin.nixosModules.catppuccin
              home-manager.nixosModules.home-manager
              nur.modules.nixos.default
              trev.nixosModules.overlay
              ./hosts/laptop/configuration.nix
            ];
          };

          desktop = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs self;
              hostname = "desktop";
            };
            modules = [
              determinate.nixosModules.default
              agenix.nixosModules.default
              catppuccin.nixosModules.catppuccin
              home-manager.nixosModules.home-manager
              nur.modules.nixos.default
              trev.nixosModules.overlay
              ./hosts/desktop/configuration.nix
            ];
          };

          htpc = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs self;
              hostname = "htpc";
            };
            modules = [
              determinate.nixosModules.default
              agenix.nixosModules.default
              catppuccin.nixosModules.catppuccin
              home-manager.nixosModules.home-manager
              nur.modules.nixos.default
              trev.nixosModules.overlay
              ./hosts/htpc/configuration.nix
            ];
          };
        }
        // servers;

        devShells = {
          default = pkgs.mkShell {
            name = "dev";
            packages = with pkgs; [
              nixfmt
              nixfmt-tree
              prettier
              podlet
              (pkgs.writeShellApplication {
                name = "secret";
                runtimeInputs = [ agenix ];
                text = ''
                  EDITOR="nano -L" agenix -e "$@"
                '';
              })
            ];

            shellHook = pkgs.shellhook.ref;
          };

          check = pkgs.mkShell {
            name = "check";
            packages = with pkgs; [
              nix-fast-build
            ];
          };

          update = pkgs.mkShell {
            name = "update";
            packages = with pkgs; [
              renovate
            ];
          };
        };

        checks = pkgs.lib.mkChecks {
          nix = {
            src = fs.toSource {
              root = ./.;
              fileset = fs.fileFilter (file: file.hasExt "nix") ./.;
            };
            deps = with pkgs; [
              nixfmt-tree
            ];
            script = ''
              treefmt --ci
            '';
          };

          actions = {
            src = fs.toSource {
              root = ./.github/workflows;
              fileset = ./.github/workflows;
            };
            deps = with pkgs; [
              action-validator
              octoscan
            ];
            script = ''
              action-validator **/*.yaml
              octoscan scan .
            '';
          };

          renovate = {
            src = fs.toSource {
              root = ./.github;
              fileset = ./.github/renovate.json;
            };
            deps = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.json
            '';
          };

          prettier = {
            src = fs.toSource {
              root = ./.;
              fileset = fs.fileFilter (file: file.hasExt "yaml" || file.hasExt "json" || file.hasExt "md") ./.;
            };
            deps = with pkgs; [
              prettier
            ];
            script = ''
              prettier --check .
            '';
          };
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
