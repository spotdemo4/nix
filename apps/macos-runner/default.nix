{
  lib,
  writeShellApplication,
  fetchurl,
  forgejo-runner,
  age,
  coreutils,
  gnused,
  jq,
  openssh,
}:
let
  # Forgejo only publishes Linux runner binaries, so build the same version for Intel macOS.
  # The runner is pure Go, so a GOOS/GOARCH build skips the nixpkgs darwin cross stdenv,
  # which nixpkgs 26.11 no longer supports for x86_64-darwin anyway.
  darwinRunner = forgejo-runner.overrideAttrs (prev: {
    pname = "forgejo-runner-darwin-amd64";
    env = (prev.env or { }) // {
      GOOS = "darwin";
      GOARCH = "amd64";
      CGO_ENABLED = "0";
    };
    # Skip act's test plugin, which is another main package
    subPackages = [ "." ];
    doCheck = false;
    doInstallCheck = false;
    # Linux strip and patchelf don't understand Mach-O, and ldflags already pass -s -w
    dontFixup = true;
    # go install puts cross-compiled binaries in bin/<goos>_<goarch>
    postInstall = ''
      mv $out/bin/darwin_amd64/runner $out/bin/forgejo-runner
      rmdir $out/bin/darwin_amd64
    '';
  });

  # Host-mode jobs run JavaScript actions such as actions/checkout with the node on PATH
  nodeVersion = "24.22.3";
  node = fetchurl {
    url = "https://nodejs.org/dist/v${nodeVersion}/node-v${nodeVersion}-darwin-x64.tar.gz";
    hash = "sha256-l3YUrwUEyBBF5/2FWW28oOX5UblmgVFtra/tzKjER/c=";
  };

  # Connection name -> agenix file with the registration TOKEN, matching hosts/build/containers.nix
  connections = {
    trev = ../../secrets/forgejo.age;
    org = ../../secrets/forgejo-org.age;
    template = ../../secrets/forgejo-template.age;
    quanta = ../../secrets/forgejo-quanta.age;
  };
in
writeShellApplication {
  name = "macos-runner";
  runtimeInputs = [
    age
    coreutils
    forgejo-runner
    gnused
    jq
    openssh
  ];
  text = ''
    FORGEJO_URL="https://trev.zip/"
    RUNNER_BIN="${darwinRunner}/bin/forgejo-runner"
    RUNNER_VERSION="${darwinRunner.version}"
    NODE_TARBALL="${node}"
    NODE_VERSION="${nodeVersion}"
    CONNECTIONS="${
      lib.concatStringsSep " " (lib.mapAttrsToList (name: file: "${name}=${file}") connections)
    }"
  ''
  + builtins.readFile ./macos-runner.sh;
  meta.description = "Install a Forgejo host-mode runner on an Intel Mac over SSH";
}
