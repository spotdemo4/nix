# shellcheck shell=bash

if (( $# != 0 )); then
  exit 2
fi

client="${TMUX_COMMAND_PICKER_CLIENT:-}"
if [[ -z "$client" ]]; then
  exit 2
fi

prefix="$(tmux display-message -p -c "$client" '#{prefix}')"
separator=$'\x1f'
declare -a entries=()

while IFS="$separator" read -r table key note; do
  [[ -n "$key" && -n "$note" ]] || continue

  case "$table" in
    prefix)
      shortcut="$prefix $key"
      ;;
    root)
      shortcut="$key"
      ;;
    *)
      continue
      ;;
  esac

  printf -v label '%-14s %s' "$shortcut" "$note"
  entries+=("$table$separator$key$separator$label")
done < <(
  tmux list-keys \
    -F '#{key_table}'"$separator"'#{key_string}'"$separator"'#{key_note}'
)

if (( ${#entries[@]} == 0 )); then
  exit 0
fi

if ! selection=$(
  printf '%s\n' "${entries[@]}" \
    | fzf \
      --delimiter="$separator" \
      --with-nth=3 \
      --prompt='tmux> ' \
      --header='Type to search | Enter: run | Esc: close' \
      --layout=reverse \
      --no-multi
); then
  exit 0
fi

IFS="$separator" read -r table key _ <<<"$selection"
exec tmux display-popup -C -c "$client" \; \
  switch-client -c "$client" -T "$table" \; \
  send-keys -K -c "$client" "$key"
