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

  cfg = config.trev.containers.gitea-runner;
  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;
  settingsFormat = pkgs.formats.yaml { };
  refs = mapAttrsToList (_: instance: instance.ref) enabledInstances;
  volumeNames = mapAttrsToList (_: instance: instance.volumeName) enabledInstances;
in
{
  options.trev.containers.gitea-runner = {
    enable = mkEnableOption "Gitea runner container instances";

    instances = mkOption {
      default = { };
      description = "Gitea runner container instances.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "the ${name} Gitea runner container";

              image = mkImageOption "docker.io/gitea/runner:3.3.2@sha256:341cc6343fe28eca1e3d5cfbe2c70d3d122c02f640eaff8103acea642a4565f3";

              url = mkOption {
                type = types.str;
                default = "";
                description = "Gitea instance URL.";
              };

              tokenFile = mkOption {
                type = types.str;
                default = "";
                description = "Environment file containing GITEA_RUNNER_REGISTRATION_TOKEN.";
              };

              name = mkOption {
                type = types.str;
                default = name;
                description = "Runner name registered with Gitea.";
              };

              labels = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Runner labels registered with Gitea.";
              };

              capacity = mkOption {
                type = types.ints.positive;
                default = 1;
                description = "Maximum number of concurrent jobs.";
              };

              settings = mkOption {
                type = settingsFormat.type;
                default = { };
                description = "Additional Gitea runner configuration.";
              };

              podmanSocket = mkOption {
                type = types.str;
                default = "/run/podman/podman.sock";
                description = "Host Podman socket exposed to the runner.";
              };

              networks = networks;

              volumeName = mkOption {
                type = types.str;
                default = "gitea-runner-${name}";
                description = "Name of the generated persistent data volume.";
              };

              ref = mkOption {
                type = types.str;
                default = "gitea-runner-${name}";
                description = "Reference name for the Gitea runner container.";
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
          message = "trev.containers.gitea-runner.instances.${name}.url must be set";
        }) enabledInstances
        ++ mapAttrsToList (name: instance: {
          assertion = instance.tokenFile != "";
          message = "trev.containers.gitea-runner.instances.${name}.tokenFile must be set";
        }) enabledInstances
        ++ mapAttrsToList (name: instance: {
          assertion = hasInfix "@sha256:" instance.image;
          message = "trev.containers.gitea-runner.instances.${name}.image must be pinned by digest";
        }) enabledInstances
        ++ [
          {
            assertion = builtins.length refs == builtins.length (unique refs);
            message = "Enabled Gitea runner instances must have unique refs";
          }
          {
            assertion = builtins.length volumeNames == builtins.length (unique volumeNames);
            message = "Enabled Gitea runner instances must have unique volume names";
          }
        ];
    }

    (mkIf (enabledInstances != { }) {
      virtualisation.quadlet = {
        containers = mapAttrs' (
          name: instance:
          let
            configFile = settingsFormat.generate "gitea-runner-${name}.yaml" (
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
              environments = {
                CONFIG_FILE = "/config.yaml";
                GITEA_INSTANCE_URL = instance.url;
                GITEA_RUNNER_LABELS = concatStringsSep "," instance.labels;
                GITEA_RUNNER_NAME = instance.name;
                RUNNER_STATE_FILE = "/data/.runner";
              };
              environmentFiles = optional (instance.tokenFile != "") instance.tokenFile;
              volumes = [
                "${instance.podmanSocket}:/var/run/docker.sock"
                "${configFile}:/config.yaml:ro"
                "${volumes.${instance.volumeName}.ref}:/data"
              ];
              networks = instance.networks;
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
