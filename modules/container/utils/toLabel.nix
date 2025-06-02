rec {
  toLabel = prefix: attrs:
    builtins.concatLists (
      builtins.attrValues (
        builtins.mapAttrs (
          k: v:
            if builtins.isAttrs v
            then toLabel (prefix ++ [k]) v
            else ["${builtins.concatStringsSep "." (prefix ++ [k])}=${toString v}"]
        )
        attrs
      )
    );
}
