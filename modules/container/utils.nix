rec {
  toEnvStrings = prefix: attrs:
    builtins.concatLists (
      builtins.attrValues (
        builtins.mapAttrs (
          k: v:
            if builtins.isAttrs v
            then toEnvStrings (prefix ++ [k]) v
            else ["${builtins.concatStringsSep "." (prefix ++ [k])}=${toString v}"]
        )
        attrs
      )
    );
}
