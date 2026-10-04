root="${1:-$PWD/shell}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cp -r "$root" "$work/qs"

find "$work/qs" -type d | while read -r dir; do
  rel="${dir#"$work"/}"
  {
    echo "module ${rel//\//.}"
    for file in "$dir"/*.qml "$dir"/*.js; do
      [ -e "$file" ] || continue
      name="$(basename "$file")"
      type="${name%.*}"
      case "$name" in
        *.js) ;;
        *)
          if grep -q '^pragma Singleton' "$file"; then
            echo "singleton $type 1.0 $name"
          elif [[ "$type" =~ ^[A-Z] ]]; then
            echo "$type 1.0 $name"
          fi
          ;;
      esac
    done
  } > "$dir/qmldir"
done

set +e
find "$work/qs" -name '*.qml' -print0 \
  | xargs -0 qmllint -I "$work" -I "$QUICKSHELL_QML" -I "$QT_QML" 2>&1 \
  | sed "s|$work/qs|$root|g"
status="${PIPESTATUS[1]}"
exit "$status"
