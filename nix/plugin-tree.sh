base="$(realpath "$1")"
plugins="$2"
out="$3"

warn() {
  echo "dotshell: $*" >&2
}

expand() {
  local dir="$1" target entry
  [ -L "$dir" ] || return 0
  target="$(readlink -f "$dir")"
  rm "$dir"
  mkdir "$dir"
  for entry in "$target"/*; do
    [ -e "$entry" ] || continue
    ln -s "$entry" "$dir/$(basename "$entry")"
  done
}

overlay() {
  local source="$1" destination="$2" owner="$3" entry name target
  for entry in "$source"/*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    target="$destination/$name"
    if [ -d "$entry" ] && [ -d "$target" ]; then
      expand "$target"
      overlay "$entry" "$target" "$owner"
      continue
    fi
    if [ -n "${claims[$target]:-}" ]; then
      warn "plugin $owner replaces ${target#"$out"/}, already replaced by ${claims[$target]}"
    fi
    claims[$target]="$owner"
    rm -rf "$target"
    ln -s "$entry" "$target"
  done
}

declare -A claims=()
installed=()
loaded=()

rm -rf "$out"

for dir in "$plugins"/*/; do
  [ -d "$dir" ] || continue
  dir="${dir%/}"
  name="$(basename "$dir")"
  if [[ ! "$name" =~ ^[a-z][a-z0-9_]*$ ]]; then
    warn "skipping plugin $name: names are lowercase letters, digits and underscores, starting with a letter"
  elif [ ! -e "$dir/Plugin.qml" ] && [ ! -d "$dir/overrides" ]; then
    warn "skipping plugin $name: it has neither Plugin.qml nor overrides/"
  else
    installed+=("$dir")
  fi
done

[ "${#installed[@]}" -gt 0 ] || exit 0

mkdir -p "$out/plugins"
for entry in "$base"/*; do
  [ "$(basename "$entry")" = plugins ] && continue
  ln -s "$entry" "$out/$(basename "$entry")"
done

for dir in "${installed[@]}"; do
  name="$(basename "$dir")"
  ln -s "$dir" "$out/plugins/$name"
  if [ -d "$dir/overrides" ]; then
    overlay "$dir/overrides" "$out" "$name"
  fi
  if [ -e "$dir/Plugin.qml" ]; then
    loaded+=("$name")
  fi
done

{
  echo "import QtQml"
  for name in "${loaded[@]}"; do
    echo "import qs.plugins.$name"
  done
  echo
  echo "QtObject {}"
} > "$out/PluginImports.qml"

echo "${loaded[*]}"
