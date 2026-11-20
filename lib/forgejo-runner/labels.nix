# CI runner labels, shared by every host that runs Forgejo and Gitea jobs
{ lib }:
rec {
  gitea = [
    "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest@sha256:433d703e6214e93234583ecc9cbec0b30fb5691259b0581597aaede21b031f8b"
    "ubuntu-24.04:docker://gitea/runner-images:ubuntu-24.04@sha256:27159f4b24a06024e6bb811624ff71e1745e3292c9117148045ce4987e072f43"
    "ubuntu-24.04-arm:docker://gitea/runner-images:ubuntu-24.04@sha256:e34fb27ad655bf1fb20d1ae6bbb71650ca29f286b3cf67e3e86dd91a90fd2976" # arch=arm64
    "ubuntu-26.04:docker://trev.zip/llc/runner-images:ubuntu-26.04@sha256:6def40a3d1ffaa80305231f3b1a08c12a8b3ea00040598c040a027f466ee975e"
    "ubuntu-26.04-arm:docker://trev.zip/llc/runner-images:ubuntu-26.04-arm@sha256:befde8e9e7fbfe5f0bca166829e226362869478b97bdc25a19eceba6bf215980" # arch=arm64
    "nixos-latest:docker://nixos/nix:2.36.0@sha256:746280551ddc1c72177d1a597c05eacac86dfaa18d5d649bf86411278bcd5470"
  ];

  # Forgejo's arm jobs run on Blacksmith through ci-bridge on the files host
  forgejo = lib.filter (label: !lib.hasInfix "-arm:" label) gitea;
}
