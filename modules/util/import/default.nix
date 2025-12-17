self: type: modules:

map (
  module:
  if builtins.pathExists self + /modules/${type}/${module}.nix then
    self + /modules/${type}/${module}.nix
  else
    self + /modules/${type}/${module}
) modules
