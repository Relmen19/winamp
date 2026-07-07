#!/usr/bin/env bash
# Full laptop health dump: GPU/drivers, display session, Wine/WACUP, audio.
# Read-only — changes NOTHING. Run: ./wine/diag.sh  (some bits nicer with sudo)
# Output goes to stdout AND a log file you can send me.
set -u

OUT="$HOME/.qmmp/wacup-logs/diag-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$OUT")"

# Everything below is teed to the log.
exec > >(tee "$OUT") 2>&1

sec() { printf '\n\n========== %s ==========\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
run() { echo "\$ $*"; "$@" 2>&1; echo; }

sec "SYSTEM"
run uname -a
run lsb_release -a
[ -r /etc/os-release ] && run cat /etc/os-release
run uptime

sec "CPU / MEM"
have lscpu && run lscpu
run free -h

sec "SESSION (Wayland vs Xorg)"
echo "XDG_SESSION_TYPE = ${XDG_SESSION_TYPE:-unset}"
echo "XDG_SESSION_DESKTOP = ${XDG_SESSION_DESKTOP:-unset}"
echo "WAYLAND_DISPLAY = ${WAYLAND_DISPLAY:-unset}"
echo "DISPLAY = ${DISPLAY:-unset}"
echo "DESKTOP_SESSION = ${DESKTOP_SESSION:-unset}"
have loginctl && {
  run loginctl
  s=$(loginctl 2>/dev/null | awk 'NR==2{print $1}')
  [ -n "${s:-}" ] && run loginctl show-session "$s" -p Type -p Desktop -p Active -p State
}

sec "GDM CONFIG (what forces Wayland/Xorg)"
[ -r /etc/gdm3/custom.conf ] && run grep -nvE '^\s*#|^\s*$' /etc/gdm3/custom.conf
[ -r /etc/gdm3/daemon.conf ] && run grep -nvE '^\s*#|^\s*$' /etc/gdm3/daemon.conf
echo "(WaylandEnable=false here => whole session runs Xorg)"

sec "GPU HARDWARE"
have lspci && run bash -c "lspci -nnk | grep -iA3 -E 'vga|3d|display'"

sec "NVIDIA STATE"
if have nvidia-smi; then
  run nvidia-smi
else
  echo "nvidia-smi NOT found — proprietary driver maybe not installed/loaded."
fi
run bash -c "lsmod | grep -iE 'nvidia|nouveau' || echo 'no nvidia/nouveau module loaded'"
have nvidia-settings && echo "nvidia-settings: present"
[ -d /proc/driver/nvidia ] && run cat /proc/driver/nvidia/version
# Ubuntu driver picker view:
have ubuntu-drivers && run ubuntu-drivers devices
run bash -c "dpkg -l | grep -iE 'nvidia-driver|nvidia-dkms|nouveau|nvidia-prime' || echo 'no matching packages'"

sec "PRIME / HYBRID GRAPHICS (laptop dual-GPU)"
have prime-select && run prime-select query
echo "-- which GPU renders GL now --"
have glxinfo && run bash -c "glxinfo 2>/dev/null | grep -iE 'OpenGL renderer|OpenGL vendor|direct rendering'" \
  || echo "glxinfo missing -> sudo apt install mesa-utils (to see renderer)"
# Wayland/EGL renderer:
have eglinfo && run bash -c "eglinfo 2>/dev/null | grep -iE 'renderer|vendor' | head"

sec "KERNEL GRAPHICS ERRORS (recent)"
have journalctl && run bash -c "journalctl -b -p err --no-pager 2>/dev/null | grep -iE 'nvidia|drm|gpu|xwayland|gdm|mutter' | tail -40 || echo 'none / no access (try sudo)'"
run bash -c "dmesg 2>/dev/null | grep -iE 'nvidia|drm|error|fail' | tail -30 || echo 'dmesg needs sudo'"

sec "X / XWAYLAND WINDOW TOOLS"
for t in Xorg Xwayland xdotool wmctrl xrandr; do
  if have "$t"; then echo "$t: $(command -v $t)"; else echo "$t: MISSING"; fi
done
have xrandr && [ -n "${DISPLAY:-}" ] && run bash -c "xrandr --query 2>/dev/null | grep -E ' connected' || true"

sec "AUDIO STACK"
echo "-- servers --"
run bash -c "pgrep -a pipewire; pgrep -a wireplumber; pgrep -a pulseaudio; true"
have pipewire && run pipewire --version
have pactl && run pactl info
have pactl && run bash -c "pactl list short sinks"
have wpctl && run wpctl status

sec "WINE"
if have wine; then
  run wine --version
  echo "WINEPREFIX(env) = ${WINEPREFIX:-unset}"
  P="$HOME/.qmmp/.wine-winamp"
  echo "expected prefix = $P  (exists: $([ -d "$P" ] && echo yes || echo NO))"
  run bash -c "dpkg -l | grep -iE 'wine|winehq' | awk '{print \$2, \$3}' || true"
  WAC="$P/drive_c/Program Files/WACUP/wacup.exe"
  echo "wacup.exe: $WAC  (exists: $([ -f "$WAC" ] && echo yes || echo NO))"
  # pending-update hang folder we mv'd earlier:
  ls -d "$P/drive_c/Program Files/WACUP/Updates"* 2>/dev/null
else
  echo "wine NOT installed?!"
fi

sec "WACUP RUNNING NOW?"
run bash -c "pgrep -a -f 'wacup.exe|winamp.exe' || echo 'not running'"

sec "DONE"
echo "LOG SAVED: $OUT"
echo "Send me that file."
