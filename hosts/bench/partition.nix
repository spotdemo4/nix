# Splits the CPU into a housekeeping core and dedicated benchmark cores.
#
# - Everything systemd starts (services, ssh sessions, nix builds) defaults to
#   the housekeeping core; `bench-run` moves a command onto free benchmark cores.
# - IRQs and unbound kernel work stay on the housekeeping core.
# - resctrl gives every core its own slice of the shared L3 cache.
# - Boost is disabled so a core's clock doesn't depend on how busy the others are.
{ lib, pkgs, ... }:
let
  # Ryzen 7 5800X: 8 cores, CPU N and CPU N+8 are the SMT threads of core N
  smtOffset = 8;
  housekeepingCore = 0;
  benchCores = lib.range 1 7;

  # Caps each core's memory bandwidth (GB/s), or null to leave it uncapped
  memoryBandwidthPerCore = null;

  cpusOf = core: [
    core
    (core + smtOffset)
  ];
  cpuList = cores: lib.concatMapStringsSep "," toString (lib.concatMap cpusOf cores);
  housekeepingCpus = cpuList [ housekeepingCore ];
  benchCpus = cpuList benchCores;

  lockDir = "/run/bench-run";
  lockFile = core: "${lockDir}/core${toString core}.lock";

  # resctrl groups as name=cpus, the first being the default group (housekeeping)
  resctrlGroups = [
    "default=${housekeepingCpus}"
  ]
  ++ map (core: "core${toString core}=${cpuList [ core ]}") benchCores;

  resctrlSetup = pkgs.writeShellApplication {
    name = "resctrl-setup";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux
    ];
    text =
      lib.replaceStrings
        [ "@groups@" "@memoryBandwidth@" ]
        [
          (lib.escapeShellArgs resctrlGroups)
          (
            # AMD expresses memory bandwidth limits in 1/8 GB/s
            if memoryBandwidthPerCore == null then "" else toString (memoryBandwidthPerCore * 8)
          )
        ]
        (builtins.readFile ./resctrl-setup.sh);
  };

  benchRun = pkgs.writeShellApplication {
    name = "bench-run";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux
    ];
    text =
      lib.replaceStrings
        [ "@cores@" "@smtOffset@" "@lockDir@" ]
        [
          (lib.concatMapStringsSep " " toString benchCores)
          (toString smtOffset)
          lockDir
        ]
        (builtins.readFile ./bench-run.sh);
  };
in
{
  boot.kernelParams = [
    # keep regular and managed (e.g. NVMe queue) interrupts off benchmark cores
    "irqaffinity=${housekeepingCpus}"
    "isolcpus=managed_irq,${benchCpus}"
    # keep unbound kernel workqueues off benchmark cores
    "workqueue.unbound_cpus=${housekeepingCpus}"
  ];

  # default affinity for PID 1 and everything it forks
  systemd.settings.Manager.CPUAffinity = housekeepingCpus;

  systemd.services.resctrl-setup = {
    description = "Partition the L3 cache between CPU cores";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = lib.getExe resctrlSetup;
    };
  };

  systemd.tmpfiles.settings."10-bench" = {
    "/sys/devices/system/cpu/cpufreq/boost".w.argument = "0";

    # not sticky, so fs.protected_regular doesn't block opening other users' lock files
    ${lockDir}.d.mode = "0755";
  }
  // lib.genAttrs ([ "${lockDir}/allocation.lock" ] ++ map lockFile benchCores) (_: {
    f.mode = "0666";
  });

  environment.systemPackages = [ benchRun ];

  users.motd =
    let
      first = toString (lib.head benchCores);
      last = toString (lib.last benchCores);
    in
    ''

      Benchmark host: run benchmarks with bench-run, not directly.

        bench-run -- hyperfine './old' './new'   pin to 1 free core (both SMT threads)
        bench-run -c 4 -- cargo bench            reserve 4 cores for multi-threaded code
        bench-run --status                       show which cores are busy, and by what

      - Cores ${first}-${last} are for benchmarks, each with its own slice of the L3 cache.
        bench-run waits until enough are free.
      - Everything else, this shell included, runs on core ${toString housekeepingCore} (CPUs ${housekeepingCpus}).
        Use bench-run -c ${toString (lib.length benchCores)} or taskset -c 0-15 for a fast build.
      - Boost is off, so clocks are fixed: compare relative %, not absolute times.
      - Only compare results that used the same core count.
      - Cores stay reserved until the command and everything it started exit.

    '';
}
