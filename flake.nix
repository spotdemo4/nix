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
      rev = "c59305bab2065cfecc4944690d9eedbb56f3a9fa";
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
      rev = "68e51a34285ceb664e74d078bcd46a15f984dfe4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home manager
    home-manager = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      rev = "acd21c5a3420a9d5fd0ed06299b10828267ef9ba";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix user repository
    nur = {
      type = "github";
      owner = "nix-community";
      repo = "NUR";
      rev = "fb84df15f5c54a572112295248b445c3fe8c5674";
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
      rev = "dadc31ade254d3009b75f2e0e2f9a6f24466363c";
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
      rev = "de74067044ec0cb870b4c97da4dadd203fc8aa62";
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
      rev = "84e6fa5d8319c6259be071f8a56cb47e8a4bec31";
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
      rev = "e56900732d1fa6f360db502451a457ffe3ca1e6e";
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
      rev = "6690dde4eea50857233b96496660de48e2e39692";
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
          cliproxyapi-fallback =
            let
              triggers = self.nixosConfigurations.etc.config.systemd.services.cliproxyapi.restartTriggers;
              templates = builtins.filter (path: pkgs.lib.hasSuffix "-cliproxyapi.json" (toString path)) triggers;
              template =
                if builtins.length templates == 1 then
                  builtins.head templates
                else
                  throw "CLIProxyAPI must have exactly one generated configuration template";
              expectedModels = pkgs.writeText "cliproxyapi-fallback-models.json" (
                builtins.toJSON {
                  "glm-5.3-flash" = "z-ai/glm-5.3-flash";
                  "gpt-6-astra" = "openai/gpt-6-astra";
                  "gpt-6-sol" = "openai/gpt-6-sol";
                  "gpt-6-luna" = "openai/gpt-6-luna";
                  "claude-haiku-4-5-20251001" = "anthropic/claude-haiku-4.5";
                  "claude-opus-5-5" = "anthropic/claude-opus-5.5";
                  "claude-sonnet-5-5" = "anthropic/claude-sonnet-5.5";
                  "claude-fable-5-1" = "anthropic/claude-fable-5.1";
                }
              );
            in
            pkgs.runCommand "cliproxyapi-fallback" { nativeBuildInputs = [ pkgs.jq ]; } ''
              jq --exit-status --slurpfile expected ${expectedModels} '
                . as $config
                | [.["openai-compatibility"][] | select(.name == "openrouter")] as $providers
                | $providers[0] as $provider
                | ($providers | length == 1)
                  and ($provider.disabled == false)
                  and ($provider.priority == -10)
                  and ($provider["base-url"] == "https://openrouter.ai/api/v1")
                  and (($provider.prefix // "") == "")
                  and (($config["force-model-prefix"] // false) == false)
                  and (($config["max-retry-credentials"] // 0) == 0)
                  and ($provider.models | length == 8)
                  and ($provider.models | map(.alias) | unique | length == 8)
                  and (($provider.models | map({key: .alias, value: .name}) | from_entries) == $expected[0])
                  and ($config["api-keys"] == [])
                  and ($provider | has("api-key-entries") | not)
                  and ($provider["key-index"] == 0)
              ' ${template}
              touch $out
            '';

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

          trev-proxy-reload =
            let
              gateway = self.nixosConfigurations.gateway;
              # Routes on other hosts reach the gateway the same way as this one.
              withRoute = gateway.extendModules {
                modules = [
                  {
                    trev.proxy.routes.reload-check = {
                      domains = [ "reload-check.trev.zip" ];
                      port = 1;
                    };
                  }
                ];
              };
              unit = nixos: nixos.config.virtualisation.quadlet.containers.trev-proxy._configText;
              configFile = nixos: nixos.config.environment.etc."trev-proxy/config.toml".source;
            in
            if unit gateway != unit withRoute then
              throw "trev-proxy's unit must not change with its routes, or route changes restart it"
            else if configFile gateway == configFile withRoute then
              throw "trev-proxy's config must change with its routes"
            else
              pkgs.runCommand "trev-proxy-reload" { } "touch $out";

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
