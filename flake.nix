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
    systems = {
      type = "github";
      owner = "spotdemo4";
      repo = "systems";
      rev = "7759b373a7b0119835939988964a9b49bc3023af";
    };
    nixpkgs = {
      type = "git";
      url = "https://github.com/nixos/nixpkgs";
      ref = "nixos-unstable";
      rev = "55bfb4d7437bd4e09ab7cba58a43bd68eb310044";
      shallow = true;
    };

    # quadlet nix
    quadlet-nix = {
      type = "github";
      owner = "SEIAROTg";
      repo = "quadlet-nix";
      rev = "db3af9df6943692c78cf9a05e3bfeb7d82e94cf3";
    };

    # determinate nix
    determinate = {
      type = "github";
      owner = "DeterminateSystems";
      repo = "determinate";
      rev = "5f516660eb6faa93f5cb83ef493345967ca719ef";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home manager
    home-manager = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      rev = "640725978b99076e18e069f6e7d2959124584f8f";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix user repository
    nur = {
      type = "github";
      owner = "nix-community";
      repo = "NUR";
      rev = "87b64dd17f045993669deba6923c3c58973a058c";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # catppuccin nix
    catppuccin = {
      type = "github";
      owner = "catppuccin";
      repo = "nix";
      rev = "2e605f61db52a45a7ff1db414df395ef566565a3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niks3
    niks3 = {
      type = "github";
      owner = "Mic92";
      repo = "niks3";
      rev = "27d6bdbf607a6e58288a8f201c87f9cac12e6727";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # agenix
    agenix = {
      type = "github";
      owner = "ryantm";
      repo = "agenix";
      rev = "3daa710894355fa2fad8243380af373a2b4046ef";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix vscode extensions
    nix4vscode = {
      type = "github";
      owner = "nix-community";
      repo = "nix4vscode";
      rev = "99d09d30901822dbdbcca8aafb7964246f5bb00b";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
      };
    };

    # trev's repository
    trevpkgs = {
      type = "github";
      owner = "spotdemo4";
      repo = "trevpkgs";
      rev = "537d40bc221d0814fd5f46aca3f042ee9b5288da";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
      };
    };

    # zen browser
    zen-browser = {
      type = "github";
      owner = "0xc000022070";
      repo = "zen-browser-flake";
      rev = "733154388e22e459c7e6dd14e6522069bbf25971";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # trevbar
    trevbar = {
      type = "github";
      owner = "spotdemo4";
      repo = "trevbar";
      rev = "29587e5382190bd818f9b7b8ac0c918839884b83";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
        trevpkgs.follows = "trevpkgs";
      };
    };

    # trev-proxy
    trev-proxy = {
      type = "git";
      url = "https://trev.zip/llc/trev-proxy";
      ref = "main";
      rev = "020c26c8738e7ea476e879a130bdaf5c8b5f4a77";
      shallow = true;
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
        trevpkgs.follows = "trevpkgs";
      };
    };

    # nix-progress
    nix-progress = {
      type = "git";
      url = "https://trev.zip/llc/nix-progress";
      ref = "main";
      rev = "35ba54546be5f559bc84aca62c86acdfee38bd7e";
      shallow = true;
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
        trevpkgs.follows = "trevpkgs";
      };
    };

    # trevdesk
    trevdesk = {
      type = "git";
      url = "https://trev.zip/llc/TrevDesk";
      ref = "main";
      rev = "e38ed5366da7000eda023de9ac33abeced49315e";
      shallow = true;
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
        trevpkgs.follows = "trevpkgs";
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
      niks3,
      trevpkgs,
      agenix,
      ...
    }@inputs:

    trevpkgs.libs.mkFlake (
      system: pkgs: {

        nixosConfigurations = nixpkgs.lib.mapAttrs (
          hostname: _:
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs self hostname;
            };
            modules = [
              determinate.nixosModules.default
              agenix.nixosModules.default
              catppuccin.nixosModules.catppuccin
              home-manager.nixosModules.home-manager
              quadlet-nix.nixosModules.quadlet
              niks3.nixosModules.default
              niks3.nixosModules.niks3-auto-upload
              nur.modules.nixos.default
              trevpkgs.nixosModules.overlay
              ./modules/nixos/journald-upload
              ./modules/nixos/nix
              ./modules/nixos/podman
              ./modules/nixos/proxy
              ./hosts/${hostname}/configuration.nix
            ];
          }
        ) (nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts));

        devShells = {
          default = pkgs.mkShell {
            shellHook = pkgs.shellhook.ref;
            packages = with pkgs; [
              bun
              podlet
              (pkgs.writeShellApplication {
                name = "secret";
                runtimeInputs = [ agenix ];
                text = ''
                  EDITOR="nano -L" agenix -e "$@"
                '';
              })

              # lint
              nixd
              nil
              lua
              shellcheck
              action-validator
              zizmor

              # format
              nixfmt
              oxfmt
              treefmt
            ];
          };

          update = pkgs.mkShell {
            packages = with pkgs; [
              renovate
              nodejs_24
              bun
            ];
          };

          vulnerable = pkgs.mkShell {
            packages = with pkgs; [
              flake-checker
              zizmor
            ];
          };
        };

        checks = pkgs.mkChecks {
          format = {
            root = ./.;
            filter =
              file:
              file.hasExt "json"
              || file.hasExt "yaml"
              || file.hasExt "toml"
              || file.hasExt "md"
              || file.hasExt "mjs"
              || file.hasExt "ts"
              || file.hasExt "tsx";
            packages = with pkgs; [
              oxfmt
            ];
            script = ''
              oxfmt --check
            '';
          };

          scripts = {
            root = ./.;
            filter = file: file.hasExt "sh";
            packages = with pkgs; [
              shellcheck
            ];
            script = ''
              shellcheck "$file"
            '';
          };

          javascript = {
            root = ./.github/actions/build;
            packages = with pkgs; [
              nodejs_24
            ];
            script = ''
              node --test index.test.mjs
            '';
          };

          actions = {
            root = ./.github;
            filter = file: file.hasExt "yaml" || file.hasExt "yml";
            packages = with pkgs; [
              action-validator
              zizmor
            ];
            script = ''
              action-validator "$file"
              zizmor --offline "$file"
            '';
          };

          nix = {
            root = ./.;
            filter = file: file.hasExt "nix";
            packages = with pkgs; [
              nixfmt
            ];
            script = ''
              nixfmt --check "$file"
            '';
          };

          lua =
            let
              # The editor config, with Hyprland's stubs from the store instead of the profile
              luarc = pkgs.writeText "luarc.json" (
                builtins.toJSON (
                  pkgs.lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ./.luarc.json)) {
                    workspace.library = [ "${pkgs.hyprland}/share/hypr/stubs" ];
                  }
                )
              );
            in
            {
              root = ./.;
              filter = file: file.hasExt "lua";
              packages = with pkgs; [
                lua-language-server
              ];
              script = ''
                lua-language-server --check . --configpath=${luarc} --logpath="$TMPDIR/lua-language-server"
              '';
            };

          renovate = {
            root = ./.github;
            fileset = ./.github/renovate.json;
            packages = with pkgs; [
              renovate
            ];
            script = ''
              renovate-config-validator renovate.json
            '';
          };
        };

        formatter = pkgs.treefmt.withConfig {
          configFile = ./treefmt.toml;
          runtimeInputs = with pkgs; [
            oxfmt
            nixfmt
          ];
        };

        schemas = trevpkgs.schemas;
      }
    );
}
