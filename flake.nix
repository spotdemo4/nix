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
      rev = "2fcb964de67fcf60b43471c55d5d99e61a9ccb5a";
      shallow = true;
    };

    # quadlet nix
    quadlet-nix = {
      type = "github";
      owner = "SEIAROTg";
      repo = "quadlet-nix";
      rev = "b6ff6c4d6b36b8e29bce417b668597fab3e03160";
    };

    # determinate nix
    determinate = {
      type = "github";
      owner = "DeterminateSystems";
      repo = "determinate";
      rev = "c5a93225f633faee482cbd0670e5d6dca0edf9de";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home manager
    home-manager = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      rev = "c554d3441f725537854e877519f01cbd60680174";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix user repository
    nur = {
      type = "github";
      owner = "nix-community";
      repo = "NUR";
      rev = "3c3a478f94811e87831e1d987a9b29a1f81af477";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # catppuccin nix
    catppuccin = {
      type = "github";
      owner = "catppuccin";
      repo = "nix";
      rev = "35d78c213b65e38789bcb359aae2380fcb4dc3e8";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niks3
    niks3 = {
      type = "github";
      owner = "Mic92";
      repo = "niks3";
      rev = "76cb73a99911bef6a395cf331c36e6f4e620c6a9";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix vscode extensions
    nix4vscode = {
      type = "github";
      owner = "nix-community";
      repo = "nix4vscode";
      rev = "27271563bd00fe5c66863f6c6153ae598aefb208";
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
      rev = "d012d3dd591bc2fcbfea441ed6b13e60633218b9";
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
      rev = "771b9a9c443d0e95815ebe2ac75e8acff99ac631";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # age nix
    agenix = {
      type = "github";
      owner = "ryantm";
      repo = "agenix";
      rev = "b027ee29d959fda4b60b57566d64c98a202e0feb";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # trevbar
    trevbar = {
      type = "github";
      owner = "spotdemo4";
      repo = "trevbar";
      rev = "7245e455d31dd1b2917ece3c733daa1965caa0ee";
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
          flake-root-paths =
            let
              flakeRoot = builtins.unsafeDiscardStringContext (toString self.outPath);
              containsFlakeRoot =
                value:
                let
                  string = toString value;
                in
                builtins.hasAttr flakeRoot (builtins.getContext string)
                || pkgs.lib.hasInfix flakeRoot (builtins.unsafeDiscardStringContext string);
              quadletOffenders = builtins.concatLists (
                pkgs.lib.mapAttrsToList (
                  host: configuration:
                  builtins.concatLists (
                    pkgs.lib.mapAttrsToList (
                      group: objects:
                      if builtins.isAttrs objects then
                        builtins.concatLists (
                          pkgs.lib.mapAttrsToList (
                            name: object:
                            pkgs.lib.optional (
                              builtins.isAttrs object && object ? _configText && containsFlakeRoot object._configText
                            ) "${host}:quadlet:${group}.${name}"
                          ) objects
                        )
                      else
                        [ ]
                    ) configuration.config.virtualisation.quadlet
                  )
                ) self.nixosConfigurations
              );
              restartTriggerOffenders = builtins.concatLists (
                pkgs.lib.mapAttrsToList (
                  host: configuration:
                  builtins.concatLists (
                    pkgs.lib.mapAttrsToList (
                      name: service:
                      pkgs.lib.optional (builtins.any containsFlakeRoot (
                        service.restartTriggers or [ ]
                      )) "${host}:restartTriggers:${name}"
                    ) configuration.config.systemd.services
                  )
                ) self.nixosConfigurations
              );
              offenders = quadletOffenders ++ restartTriggerOffenders;
            in
            if offenders != [ ] then
              throw ''
                generated service configuration contains paths rooted in this flake:
                ${pkgs.lib.concatStringsSep "\n" offenders}
              ''
            else
              pkgs.runCommand "flake-root-paths" { } "touch $out";

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

          lua = {
            root = ./.;
            filter = file: file.hasExt "lua";
            packages = with pkgs; [
              lua
            ];
            script = ''
              luac -p "$file"
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
