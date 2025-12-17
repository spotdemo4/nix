type: modules:

map (
  module:
  if builtins.pathExists ../../${type}/${module}.nix then
    ../../${type}/${module}.nix
  else
    ../../${type}/${module}
) modules
