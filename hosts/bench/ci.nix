# Runs Forgejo CI jobs on the benchmark cores while no benchmark needs them.
#
# - Each worker reserves cores with `bench-run --ci`, then runs at most one job with
#   `forgejo-runner one-job` in podman containers pinned to those cores. Cores are released
#   between jobs, so a benchmark never waits on an idle runner.
# - bench-run keeps CI and benchmarks apart: once a benchmark is waiting, workers start no
#   new jobs, and the benchmark starts when the running jobs finish.
# - The runner registers with the same scopes and labels as the build host, so the bench
#   host picks up whatever the build host hasn't taken yet.
# - Stopping a worker (including on a deploy that changes it) cancels its running job.
{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  workers = 3;
  coresPerJob = 2;
  # seconds a worker waits after finding no job in any scope
  pollInterval = 10;

  user = "bench-ci";
  url = "https://trev.zip/";
  socket = "/run/podman/podman.sock";
  labels = (import (self + /lib/forgejo-runner/labels.nix) { inherit lib; }).forgejo;

  # scope -> registration token secret, matching the build host's runners
  connections = {
    trev = "forgejo";
    org = "forgejo-org";
    template = "forgejo-template";
    quanta = "forgejo-quanta";
  };

  # the job script fills in the registration, cache directory and cores
  baseConfig = (pkgs.formats.json { }).generate "bench-ci.json" {
    # job output goes to Forgejo, and idle polling would flood the journal at info
    log.level = "warn";
    runner = {
      capacity = 1;
      inherit labels;
    };
    cache.enabled = true;
    container = {
      network = "host";
      privileged = true;
      docker_host = "unix://${socket}";
    };
  };

  register = pkgs.writeShellApplication {
    name = "bench-ci-register";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      forgejo-runner
      gnused
      jq
    ];
    runtimeEnv = {
      URL = url;
      NAME = config.networking.hostName;
      VERSION = "v${pkgs.forgejo-runner.version}";
      LABELS = lib.concatStringsSep " " labels;
      CONNECTIONS = lib.concatStringsSep " " (
        lib.mapAttrsToList (conn: secret: "${conn}=${config.age.secrets.${secret}.path}") connections
      );
    };
    text = builtins.readFile ./ci-register.sh;
  };

  job = pkgs.writeShellApplication {
    name = "bench-ci-job";
    runtimeInputs = with pkgs; [
      coreutils
      forgejo-runner
      gnugrep
      jq
    ];
    runtimeEnv.BASE_CONFIG = baseConfig;
    text = builtins.readFile ./ci-job.sh;
  };

  worker = pkgs.writeShellApplication {
    name = "bench-ci-worker";
    runtimeInputs = [
      config.bench.run
      pkgs.coreutils
    ];
    runtimeEnv = {
      CONNECTIONS = lib.concatStringsSep " " (lib.attrNames connections);
      CORES = coresPerJob;
      INTERVAL = pollInterval;
      WORKERS = workers;
      JOB = lib.getExe job;
    };
    text = builtins.readFile ./ci-worker.sh;
  };
in
{
  assertions = [
    {
      assertion = workers * coresPerJob <= lib.length config.bench.cores;
      message = "bench CI workers need more cores than the host reserves for benchmarks";
    }
  ];

  virtualisation.podman = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
    };
  };
  # resolve short image names like gitea/runner-images without asking which registry
  virtualisation.containers.registries.settings.unqualified-search-registries = [ "docker.io" ];

  # the ubuntu-*-arm labels run arm64 images
  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  users = {
    groups.${user} = { };
    users.${user} = {
      isSystemUser = true;
      group = user;
      # access to the podman socket, which is effectively root
      extraGroups = [ "podman" ];
    };
  };

  age.secrets = lib.mapAttrs' (
    _: secret:
    lib.nameValuePair secret {
      file = self + /secrets/${secret}.age;
      owner = user;
    }
  ) connections;

  systemd.services = {
    bench-ci-register = {
      description = "Register the bench host's Forgejo runners";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = user;
        Group = user;
        StateDirectory = "bench-ci";
        StateDirectoryMode = "0700";
        ExecStart = lib.getExe register;
        Restart = "on-failure";
        RestartSec = 30;
      };
    };
  }
  // lib.listToAttrs (
    map (
      slot:
      lib.nameValuePair "bench-ci-${toString slot}" {
        description = "Bench host CI worker ${toString slot}";
        wantedBy = [ "multi-user.target" ];
        requires = [
          "bench-ci-register.service"
          "podman.socket"
        ];
        after = [
          "bench-ci-register.service"
          "podman.socket"
        ];
        environment.SLOT = toString slot;
        serviceConfig = {
          User = user;
          Group = user;
          StateDirectory = "bench-ci";
          StateDirectoryMode = "0700";
          RuntimeDirectory = "bench-ci-${toString slot}";
          ExecStart = lib.getExe worker;
          Restart = "always";
          RestartSec = 10;
          # leave the runner time to cancel its job and remove the containers
          TimeoutStopSec = 120;
        };
      }
    ) (lib.range 1 workers)
  );
}
