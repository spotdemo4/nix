{
  inputs,
  self,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
  };
}
