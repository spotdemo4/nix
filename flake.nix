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
      rev = "fe13242281a67641c0102cdb1087f0ebe586c7df";
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
      rev = "ec80131710bffcdf3b8498cf41f3a0579833b023";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix user repository
    nur = {
      type = "github";
      owner = "nix-community";
      repo = "NUR";
      rev = "25c7c84df19b1b66c4266812f9a0d39417a69082";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # catppuccin nix
    catppuccin = {
      type = "github";
      owner = "catppuccin";
      repo = "nix";
      rev = "30c87b95a628e81ec82a4fa0ed4db85d7c7d46d6";
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
      rev = "5e5b88a0c8e56f291a108c2fe9934054d9745b2e";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix vscode extensions
    nix4vscode = {
      type = "github";
      owner = "nix-community";
      repo = "nix4vscode";
      rev = "1986e6b54fc19c16757be51d628ae70b355fe6a1";
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
      rev = "c5380a813ab0fca42cccd16c02d96e4cff06a611";
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
      rev = "f19490ac889eabb05bdb7e8dcb85225ee75bd87b";
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
      rev = "d36b234ccba3958b4d70fc182fd8e779e15bd3a0";
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
      rev = "d88e2b2dc9526f2c2ac82ffec0b6e6a5f8968de2";
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
      rev = "eb59749dcc1784634ae778e15c7bfff4e6a6a6a3";
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
      rev = "75fe21ecccbe31814b15c8307d2de20447d51c32";
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
