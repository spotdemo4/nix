# CI runner labels, shared by every host that runs Forgejo and Gitea jobs
{ lib }:
rec {
  gitea = [
    "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest@sha256:b96ba465021b1a4c6a1c9e79220c2b9bfad0f29b09dbb528bbfb35411443a3a4"
    "ubuntu-24.04:docker://gitea/runner-images:ubuntu-24.04@sha256:b96ba465021b1a4c6a1c9e79220c2b9bfad0f29b09dbb528bbfb35411443a3a4"
    "ubuntu-24.04-arm:docker://gitea/runner-images:ubuntu-24.04@sha256:e34fb27ad655bf1fb20d1ae6bbb71650ca29f286b3cf67e3e86dd91a90fd2976" # arch=arm64
    "ubuntu-26.04:docker://trev.zip/llc/runner-images:ubuntu-26.04@sha256:6def40a3d1ffaa80305231f3b1a08c12a8b3ea00040598c040a027f466ee975e"
    "ubuntu-26.04-arm:docker://trev.zip/llc/runner-images:ubuntu-26.04-arm@sha256:befde8e9e7fbfe5f0bca166829e226362869478b97bdc25a19eceba6bf215980" # arch=arm64
    "nixos-latest:docker://nixos/nix:2.35.6@sha256:b49cb33f3a7e5cf3933ad8774529de0e3807ec5cf54987aa7ccdfb49f2fc55ed"
  ];

  # Forgejo runners need the platform spelled out to pull the arm64 images
  forgejo = map (
    label: label + lib.optionalString (lib.hasInfix "-arm:" label) "?platform=linux/arm64"
  ) gitea;
}
