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
      rev = "4975466d324710c576dc11ad614684e6bd8cad8e";
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
      rev = "35e914102d4992b10bac4c12e94ec606d109633d";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home manager
    home-manager = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      rev = "7b4c5ec4bedaf1e062bbc1bcaeddbc6bd242aa1b";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix user repository
    nur = {
      type = "github";
      owner = "nix-community";
      repo = "NUR";
      rev = "3985fdf87c1c767a3a7fe8f30018907a47a7e2fa";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # catppuccin nix
    catppuccin = {
      type = "github";
      owner = "catppuccin";
      repo = "nix";
      rev = "89b3eacf59d6b5eefbc2d69c3a4eb5aaf66d63bc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niks3
    niks3 = {
      type = "github";
      owner = "Mic92";
      repo = "niks3";
      rev = "e64338d774d97249ce0ace37a59767e72b5b52fb";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix vscode extensions
    nix4vscode = {
      type = "github";
      owner = "nix-community";
      repo = "nix4vscode";
      rev = "2fc306f6d2c9b3ea22391f34bc447b8c9e529563";
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
      rev = "acbcadf78bbcb1d1fc8c7b61347dfed644913599";
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
      rev = "2b7fec6557495d97736f1b31904f79312671ca2a";
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
      rev = "ffe1193c5918ea5de352a3a3de16b284ebf7397d";
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
          forgejo-archive-storage =
            let
              quadlet = self.nixosConfigurations.files.config.virtualisation.quadlet;
              container = quadlet.containers.forgejo._configText;
              volume = quadlet.volumes.forgejo-archive-cache;
              lines = pkgs.lib.splitString "\n" volume._configText;
              required = [
                "VolumeName=forgejo-archive-cache"
                "Copy=false"
                "PodmanArgs=--uid=1000"
                "PodmanArgs=--gid=1000"
              ];
              persistent =
                volume.volumeConfig.device == null
                && volume.volumeConfig.type == null
                && volume.volumeConfig.options == null
                && builtins.elem volume.volumeConfig.driver [
                  null
                  "local"
                ];
            in
            if
              !persistent
              || !(builtins.all (line: builtins.elem line lines) required)
              || !(builtins.elem "Volume=forgejo-archive-cache.volume:/data/gitea/repo-archive" (
                pkgs.lib.splitString "\n" container
              ))
              || quadlet.volumes ? forgejo-repo-archive
              || pkgs.lib.hasInfix "forgejo-repo-archive.volume" container
            then
              throw "Forgejo archives must use a new persistent volume owned by UID/GID 1000"
            else
              pkgs.runCommand "forgejo-archive-storage" { } "touch $out";

          runner-docker =
            let
              build = self.nixosConfigurations.build.config;
              runners = [
                "forgejo-runner-trev"
                "forgejo-runner-org"
                "forgejo-runner-template"
                "gitea-runner-quanta"
              ];
              offenders = builtins.filter (
                name:
                let
                  text = build.virtualisation.quadlet.containers.${name}._configText;
                  lines = pkgs.lib.splitString "\n" text;
                  required = [
                    "Volume=/run/docker.sock:/var/run/docker.sock"
                    "Volume=${name}.volume:/data"
                    "Requires=docker.service docker.socket"
                    "After=docker.service docker.socket"
                    "PartOf=docker.service docker.socket"
                  ];
                in
                !(builtins.all (line: builtins.elem line lines) required) || pkgs.lib.hasInfix "podman.sock" text
              ) runners;
            in
            if !build.virtualisation.docker.enable || offenders != [ ] then
              throw ''
                build runners must use native Docker and preserve their state volumes:
                ${pkgs.lib.concatStringsSep "\n" offenders}
              ''
            else
              pkgs.runCommand "runner-docker" { } "touch $out";

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
