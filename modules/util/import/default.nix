{
  type,
  modules,
}:
map (
  module:
  if builtins.pathExists ../../modules/${type}/${module}.nix then
    ../../modules/${type}/${module}.nix
  else
    ../../modules/${type}/${module}
) modules
