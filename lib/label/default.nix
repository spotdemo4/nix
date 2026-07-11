{
  prefix ? [ ],
  attrs,
}:
let
  toLabel =
    currentPrefix: currentAttrs:
    builtins.concatLists (
      builtins.attrValues (
        builtins.mapAttrs (
          key: value:
          if builtins.isAttrs value then
            toLabel (currentPrefix ++ [ key ]) value
          else
            [ "${builtins.concatStringsSep "." (currentPrefix ++ [ key ])}=${toString value}" ]
        ) currentAttrs
      )
    );
in
toLabel prefix attrs
