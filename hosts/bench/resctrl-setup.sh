# shellcheck shell=bash
# Splits the L3 cache evenly between resctrl groups, one per set of CPUs.
set -euo pipefail

root=/sys/fs/resctrl

# name=cpus, the first being the default group
groups=(@groups@)

# memory bandwidth limit per group in the schemata's units, empty for no limit
memory_bandwidth="@memoryBandwidth@"

if ! mountpoint -q "$root"; then
  mount -t resctrl resctrl "$root"
fi

if [[ ! -d $root/info/L3 ]]; then
  echo "resctrl-setup: L3 cache allocation is not supported" >&2
  exit 1
fi

names=()
for group in "${groups[@]}"; do
  names+=("${group%%=*}")
done

# remove groups that are no longer configured
for dir in "$root"/*/; do
  name=$(basename "$dir")
  case $name in
  info | mon_groups | mon_data) continue ;;
  esac
  if [[ " ${names[*]} " != *" $name "* ]]; then
    rmdir "$dir"
  fi
done

mask=$((16#$(cat "$root/info/L3/cbm_mask")))
min_bits=$(cat "$root/info/L3/min_cbm_bits")
ways=0
while ((mask)); do
  ways=$((ways + (mask & 1)))
  mask=$((mask >> 1))
done
per_group=$((ways / ${#groups[@]}))
if ((per_group < min_bits)); then
  echo "resctrl-setup: $ways cache ways can't be split between ${#groups[@]} groups" >&2
  exit 1
fi

# cache domain ids, e.g. "0" for a single L3
mapfile -t domains < <(sed -n 's/^ *L3:\(.*\)$/\1/p' "$root/schemata" | tr ';' '\n' | cut -d= -f1)

schema() {
  local resource=$1 value=$2 domain parts=()
  for domain in "${domains[@]}"; do
    parts+=("$domain=$value")
  done
  local IFS=';'
  echo "$resource:${parts[*]}"
}

for i in "${!groups[@]}"; do
  name=${groups[$i]%%=*}
  cpus=${groups[$i]#*=}

  if ((i == 0)); then
    # the default group gets whatever CPUs no other group claims
    dir=$root
  else
    dir=$root/$name
    mkdir -p "$dir"
    echo "$cpus" >"$dir/cpus_list"
  fi

  bits=$((((1 << per_group) - 1) << (i * per_group)))
  schema L3 "$(printf '%x' "$bits")" >"$dir/schemata"

  if [[ -n $memory_bandwidth ]]; then
    if [[ -d $root/info/MB ]]; then
      schema MB "$memory_bandwidth" >"$dir/schemata"
    else
      echo "resctrl-setup: memory bandwidth allocation is not supported" >&2
    fi
  fi

  echo "resctrl-setup: $name (CPUs $cpus): $(tr '\n' ' ' <"$dir/schemata")"
done
