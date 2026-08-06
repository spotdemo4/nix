{ inputs, ... }:
{
  # Pin `nix shell nixpkgs#...` and `nix run nixpkgs#...` to the nixpkgs locked in
  # flake.nix:24 / flake.lock:399 instead of Determinate's flakehub
  # https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1 which is
  # injected via /etc/nix/nix.conf:7 extra-nix-path and
  # /etc/nix/registry.json:1 / .direnv/.../determinate/modules/nixos.nix:33
  # Determinate guards with `mkIf (config.nix.registry.nixpkgs.flake or null == null)`
  # so a normal assignment (priority 100) overrides its mkPreferable 750.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # Pin legacy `nix-shell -p ...`, `nix-shell '<nixpkgs>'` and `import <nixpkgs>`
  # which resolve via NIX_PATH / nix.nixPath / nix.settings.nix-path, not the
  # flake registry. Without this, nix-shell uses Determinate's
  # extra-nix-path=nixpkgs=flake:https://flakehub.com/...
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
}
