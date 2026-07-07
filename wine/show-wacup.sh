#!/usr/bin/env bash
# Find WACUP/Winamp X11 windows, print their geometry, and force them onto the
# visible screen. Run this WHILE WACUP is open (icon in the dash).
set -u

for t in xdotool wmctrl; do
  command -v "$t" >/dev/null || { echo "MISSING $t -> sudo apt install -y xdotool wmctrl"; exit 1; }
done

# Collect candidate window ids by name and by class.
ids=$( { xdotool search --name -i winamp; xdotool search --class -i wacup; } 2>/dev/null | sort -u )
[ -z "$ids" ] && { echo "No WACUP window found. Is it running?"; exit 1; }

echo "=== windows found ==="
for id in $ids; do
  name=$(xdotool getwindowname "$id" 2>/dev/null)
  geo=$(xdotool getwindowgeometry "$id" 2>/dev/null | tr '\n' ' ')
  echo "[$id] name='$name' :: $geo"
done

echo "=== forcing each onto screen (100,100 +) ==="
x=100
for id in $ids; do
  xdotool windowmove "$id" "$x" "$x" 2>/dev/null
  xdotool windowactivate "$id" 2>/dev/null
  wmctrl -i -a "$id" 2>/dev/null
  x=$((x+50))
done
echo "done. See anything now? If still blank -> transparency/layered issue, not position."
