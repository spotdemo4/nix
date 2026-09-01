{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    filterAttrs
    hasInfix
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    nameValuePair
    optional
    recursiveUpdate
    types
    unique
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    networks
    ;
  inherit (config.virtualisation.quadlet) volumes;

  cfg = config.trev.containers.forgejo-runner;
  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;
  settingsFormat = pkgs.formats.yaml { };
  refs = mapAttrsToList (_: instance: instance.ref) enabledInstances;
  volumeNames = mapAttrsToList (_: instance: instance.volumeName) enabledInstances;
  entrypoint = pkgs.writeText "forgejo-runner-entrypoint.sh" ''
    set -eu

    : "''${TOKEN:?TOKEN must be set}"
    : "''${FORGEJO_INSTANCE_URL:?FORGEJO_INSTANCE_URL must be set}"
    : "''${FORGEJO_RUNNER_NAME:?FORGEJO_RUNNER_NAME must be set}"
    : "''${CONFIG_FILE:?CONFIG_FILE must be set}"

    cd /data

    if [ ! -s /data/.runner ]; then
      set -- register \
        --no-interactive \
        --instance "$FORGEJO_INSTANCE_URL" \
        --token "$TOKEN" \
        --name "$FORGEJO_RUNNER_NAME" \
        --config "$CONFIG_FILE"

      if [ -n "''${FORGEJO_RUNNER_LABELS:-}" ]; then
        set -- "$@" --labels "$FORGEJO_RUNNER_LABELS"
      fi

      forgejo-runner "$@"
    fi

    exec forgejo-runner daemon --config "$CONFIG_FILE"
  '';
in
{
  options.trev.containers.forgejo-runner = {
    enable = mkEnableOption "Forgejo runner container instances";

    instances = mkOption {
      default = { };
      description = "Forgejo runner container instances.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "the ${name} Forgejo runner container";

              image = mkImageOption "code.forgejo.org/forgejo/runner:13.1.0@sha256:c4af85fd9f0dd03788676a534781a87c71aa2c6a37737143e017eb94d4312952";

              url = mkOption {
                type = types.str;
                default = "";
                description = "Forgejo instance URL.";
              };

              tokenFile = mkOption {
                type = types.str;
                default = "";
                description = "Environment file containing TOKEN.";
              };

              name = mkOption {
                type = types.str;
                default = name;
                description = "Runner name registered with Forgejo.";
              };

              labels = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Runner labels registered with Forgejo.";
              };

              capacity = mkOption {
                type = types.ints.positive;
                default = 1;
                description = "Maximum number of concurrent jobs.";
              };

              settings = mkOption {
                type = settingsFormat.type;
                default = { };
                description = "Additional Forgejo runner configuration.";
              };

              podmanSocket = mkOption {
                type = types.str;
                default = "/run/podman/podman.sock";
                description = "Host Podman socket exposed to the runner.";
              };

              networks = networks;

              volumeName = mkOption {
                type = types.str;
                default = "forgejo-runner-${name}";
                description = "Name of the generated persistent data volume.";
              };

              ref = mkOption {
                type = types.str;
                default = "forgejo-runner-${name}";
                description = "Reference name for the Forgejo runner container.";
              };
            };
          }
        )
      );
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions =
        mapAttrsToList (name: instance: {
          assertion = instance.url != "";
          message = "trev.containers.forgejo-runner.instances.${name}.url must be set";
        }) enabledInstances
        ++ mapAttrsToList (name: instance: {
          assertion = instance.tokenFile != "";
          message = "trev.containers.forgejo-runner.instances.${name}.tokenFile must be set";
        }) enabledInstances
        ++ mapAttrsToList (name: instance: {
          assertion = hasInfix "@sha256:" instance.image;
          message = "trev.containers.forgejo-runner.instances.${name}.image must be pinned by digest";
        }) enabledInstances
        ++ [
          {
            assertion = builtins.length refs == builtins.length (unique refs);
            message = "Enabled Forgejo runner instances must have unique refs";
          }
          {
            assertion = builtins.length volumeNames == builtins.length (unique volumeNames);
            message = "Enabled Forgejo runner instances must have unique volume names";
          }
        ];
    }

    (mkIf (enabledInstances != { }) {
      virtualisation.quadlet = {
        containers = mapAttrs' (
          name: instance:
          let
            configFile = settingsFormat.generate "forgejo-runner-${name}.yaml" (
              recursiveUpdate instance.settings {
                runner = {
                  file = "/data/.runner";
                  inherit (instance) capacity labels;
                };
                container.docker_host = "unix:///var/run/docker.sock";
              }
            );
          in
          nameValuePair instance.ref {
            containerConfig = mkContainer {
              image = instance.image;
              pull = "missing";
              entrypoint = "/bin/sh";
              exec = [ "/entrypoint.sh" ];
              environments = {
                CONFIG_FILE = "/config.yaml";
                FORGEJO_INSTANCE_URL = instance.url;
                FORGEJO_RUNNER_LABELS = concatStringsSep "," instance.labels;
                FORGEJO_RUNNER_NAME = instance.name;
              };
              environmentFiles = optional (instance.tokenFile != "") instance.tokenFile;
              volumes = [
                "${instance.podmanSocket}:/var/run/docker.sock"
                "${configFile}:/config.yaml:ro"
                "${entrypoint}:/entrypoint.sh:ro"
                "${volumes.${instance.volumeName}.ref}:/data"
              ];
              networks = instance.networks;
              user = "0";
              workdir = "/data";
            };

            unitConfig = {
              After = "podman.socket";
              BindsTo = "podman.socket";
              ReloadPropagatedFrom = "podman.socket";
            };
          }
        ) enabledInstances;

        volumes = mapAttrs' (_: instance: nameValuePair instance.volumeName { }) enabledInstances;
      };
    })
  ]);
}
