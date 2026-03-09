#!/usr/bin/env bash

HOSTS=$(nix flake show --json | jq -c '.nixosConfigurations | keys' | jq -c)
echo "hosts=$HOSTS" >> "$GITHUB_OUTPUT"
