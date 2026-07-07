#!/usr/bin/env bash
# Find every WACUP/Winamp window and force it onto the visible screen + raise it.
# Works around Wayland/XWayland windows that map off-screen or invisible.
# Run WHILE WACUP is open.
set -u

for t in xdotool wmctrl; do
  command -v "$t" >/dev/null || { echo "MISSING $t -> sudo apt install -y xdotool wmctrl"; exit 1; }
done

# WACUP's skinned child windows carry these names (class is unreadable on XWayland).
NAME_RE='WACUP|Winamp|Player Window|Playlist Editor|Album Art|Media Library|Big Clock|Waveform Seeker|Lyrics|Excluded Files'

# ids by name (regex) + ids of managed wacup.exe windows via wmctrl.
ids=$(
  { xdotool search --name "$NAME_RE" 2>/dev/null
    wmctrl -lx 2>/dev/null | awk '/wacup\.exe/{print strtonum($1)}'
  } | sort -un
)
[ -z "$ids" ] && { echo "No WACUP window found. Is it running?"; exit 1; }

echo "=== windows found ==="
for id in $ids; do
  printf '[%s] %-20s :: %s\n' "$id" "'$(xdotool getwindowname "$id" 2>/dev/null)'" \
    "$(xdotool getwindowgeometry "$id" 2>/dev/null | tr '\n' ' ')"
done

echo "=== mapping + moving onto screen ==="
x=80
for id in $ids; do
  xdotool windowmap "$id" 2>/dev/null      # in case it never mapped
  xdotool windowmove "$id" "$x" "$x" 2>/dev/null
  xdotool windowactivate "$id" 2>/dev/null
  wmctrl -i -a "$id" 2>/dev/null
  x=$((x+40))
done
echo "done."
