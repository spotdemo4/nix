{
  config,
  lib,
  self,
  ...
}:
let
  labels = [
    "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest@sha256:fd911d7417bfbf0f454530e447da95b58001e1df41bbc5e1a8dd35d432575aae"
    "ubuntu-24.04:docker://gitea/runner-images:ubuntu-24.04@sha256:fd911d7417bfbf0f454530e447da95b58001e1df41bbc5e1a8dd35d432575aae"
    "ubuntu-24.04-arm:docker://gitea/runner-images:ubuntu-24.04@sha256:e34fb27ad655bf1fb20d1ae6bbb71650ca29f286b3cf67e3e86dd91a90fd2976" # arch=arm64
    "ubuntu-26.04:docker://trev.zip/llc/runner-images:ubuntu-26.04@sha256:6def40a3d1ffaa80305231f3b1a08c12a8b3ea00040598c040a027f466ee975e"
    "ubuntu-26.04-arm:docker://trev.zip/llc/runner-images:ubuntu-26.04-arm@sha256:befde8e9e7fbfe5f0bca166829e226362869478b97bdc25a19eceba6bf215980" # arch=arm64
    "nixos-latest:docker://nixos/nix:2.35.2@sha256:7a007c766426c1877758ddc5cb87a965ac131fc78c582ce0083d922d51ae945c"
  ];
  runner = {
    enable = true;
    name = "builder";
    inherit labels;
    capacity = 2;
    networks = [ "host" ];
    settings.container = {
      network = "host";
      privileged = true;
    };
  };
  forgejoRunner = runner // {
    url = "https://trev.zip/";
    labels = map (
      label: label + lib.optionalString (lib.hasInfix "-arm:" label) "?platform=linux/arm64"
    ) labels;
  };
in
{
  imports = [
    (self + /modules/container/forgejo-runner)
    (self + /modules/container/gitea-runner)
    (self + /modules/container/portainer-agent)
  ];

  trev.containers = {
    forgejo-runner = {
      enable = true;
      instances = {
        trev = forgejoRunner // {
          tokenFile = config.age.secrets."forgejo".path;
        };
        org = forgejoRunner // {
          tokenFile = config.age.secrets."forgejo-org".path;
        };
        template = forgejoRunner // {
          tokenFile = config.age.secrets."forgejo-template".path;
        };
      };
    };

    gitea-runner = {
      enable = true;
      instances.quanta = runner // {
        url = "https://git.quantadev.cc/";
        tokenFile = config.age.secrets."quanta-runner".path;
      };
    };

    portainer-agent.enable = true;
  };
}
