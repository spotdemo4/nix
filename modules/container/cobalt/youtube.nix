{
  config,
  ...
}:
let
  inherit (config) gluetun;
in
{
  virtualisation.quadlet.containers.cobalt-youtube = {
    containerConfig = {
      image = "ghcr.io/imputnet/yt-session-generator:webserver@sha256:95b801ce70c93dfa7a0732fa52d41ef0fe891489e72926360bd50aa001797d5d";
      pull = "missing";
      networks = [
        "container:${gluetun."cobalt".ref}"
      ];
    };
  };
}
