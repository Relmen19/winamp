#!/usr/bin/env bash
# Launch WACUP (Winamp) under Wine with logging so we can see WHY tracks skip
# or windows hang. Pass a file to auto-play it: ./run-wacup.sh /path/to/track.flac
set -u

export WINEPREFIX="$HOME/.qmmp/.wine-winamp"
WACUP="$WINEPREFIX/drive_c/Program Files/WACUP/wacup.exe"

# Log dir next to the prefix.
LOGDIR="$HOME/.qmmp/wacup-logs"
mkdir -p "$LOGDIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$LOGDIR/wacup-$STAMP.log"

# fixme spam off; keep errors + warnings, and DLL/plugin load info.
export WINEDEBUG="fixme-all,err+all,warn+module,+loaddll"

echo "prefix : $WINEPREFIX"          | tee    "$LOG"
echo "wacup  : $WACUP"               | tee -a "$LOG"
echo "wine   : $(wine --version)"    | tee -a "$LOG"
echo "args   : $*"                   | tee -a "$LOG"
echo "-----------------------------" | tee -a "$LOG"

# Convert any Linux file args to Windows paths WACUP understands.
winargs=()
for a in "$@"; do
  if [ -e "$a" ]; then
    winargs+=("$(winepath -w "$a" 2>/dev/null || echo "$a")")
  else
    winargs+=("$a")
  fi
done

wine "$WACUP" "${winargs[@]}" 2>&1 | tee -a "$LOG"

echo "-----------------------------"
echo "LOG SAVED: $LOG"
echo "Send me that file (or: grep -iE 'err|fail|plugin|in_|decode' \"$LOG\")"
