let
  inherit (./keys.nix) keys;
in {
  "guest_accounts.json.age".publicKeys = keys;
}
