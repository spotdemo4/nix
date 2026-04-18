{
  description = "trev's config flake";

  nixConfig = {
    extra-substituters = [
      "https://nix.trev.zip"
      "https://install.determinate.systems"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "trev:I39N/EsnHkvfmsbx8RUW+ia5dOzojTQNCTzKYij1chU="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    systems.url = "github:spotdemo4/systems";
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
      url = "github:nix-community/nix4vscode/b69acee4ba8dffcfa553c9a7ba19984db1a1c3a7";
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
      system: pkgs:
      let
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
            packages = with pkgs; [
              nix-fast-build
            ];
          };

          update = pkgs.mkShell {
            packages = with pkgs; [
              renovate
            ];
          };

          vulnerable = pkgs.mkShell {
            packages = with pkgs; [
              # nix
              flake-checker

              # actions
              octoscan
            ];
          };
        };

        checks = pkgs.mkChecks {
          actions = {
            root = ./.github/workflows;
            fileset = ./.github/workflows;
            deps = with pkgs; [
              action-validator
              octoscan
            ];
            forEach = ''
              action-validator "$file"
              octoscan scan "$file"
            '';
          };

          shellcheck = {
            root = ./.;
            filter = file: file.hasExt "sh";
            deps = with pkgs; [
              shellcheck
            ];
            forEach = ''
              shellcheck "$file"
            '';
          };

          renovate = {
            root = ./.github;
            fileset = ./.github/renovate.json;
            deps = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.json
            '';
          };

          nix = {
            root = ./.;
            filter = file: file.hasExt "nix";
            deps = with pkgs; [
              nixfmt
            ];
            forEach = ''
              nixfmt --check "$file"
            '';
          };

          prettier = {
            root = ./.;
            filter = file: file.hasExt "yaml" || file.hasExt "json" || file.hasExt "md";
            deps = with pkgs; [
              prettier
            ];
            forEach = ''
              prettier --check "$file"
            '';
          };
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
