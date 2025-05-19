{config, ...}: {
  imports =
    [
      ../hosts/lxc/configuration.nix
    ]
    ++ map (x: ./../modules/nixos/${x}.nix) [
      # Programs to import
      "update"
    ];

  networking.hostName = "build";

  # Update script
  update = {
    enable = true;
    hostname = "build";
    user = "trev";
  };

  # Gitea runner
  age.secrets."gitea-runner".file = ./../secrets/gitea-runner.age;
  virtualisation.oci-containers.containers = {
    gitea-act-runner = {
      image = "gitea/act_runner:nightly";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      environment = {
        GITEA_INSTANCE_URL = "https://git.quantadev.cc";
      };
      environmentFiles = [
        config.age.secrets."gitea-runner".path
      ];
    };
  };
}
