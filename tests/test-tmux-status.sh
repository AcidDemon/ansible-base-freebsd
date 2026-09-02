#!/bin/sh
# Feeds tmux-status.sh the exact shape FreeBSD's sysctl prints, with a boot time
# one day back, and checks what it reports. The boottime parse used to lead with
# a greedy .*, which ran past "sec = " and matched the one inside "usec = ", so
# every box read the microseconds and reported an uptime counted from the epoch.
set -u
here=$(cd "$(dirname "$0")" >/dev/null && pwd)
script="$here/../roles/tmux/files/tmux-status.sh"
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"

BOOT=1756742400        # 2026-09-01 12:00:00 UTC
NOW=1756828800         # exactly one day later

cat > "$work/bin/sysctl" <<EOF
#!/bin/sh
case "\$2" in
  kern.boottime) echo "{ sec = $BOOT, usec = 51840 } Tue Sep  1 12:00:00 2026" ;;
  vm.loadavg)    echo "{ 0.10 0.20 0.30 }" ;;
  hw.physmem)    echo 8589934592 ;;
  hw.pagesize)   echo 4096 ;;
  vm.stats.vm.v_free_count)     echo 1000000 ;;
  vm.stats.vm.v_inactive_count) echo 100000 ;;
  *) exit 1 ;;
esac
EOF
cat > "$work/bin/date" <<EOF
#!/bin/sh
case "\${1:-}" in
  +%s) echo $NOW ;;
  *)   echo "2026-09-02 12:00" ;;
esac
EOF
printf '#!/bin/sh\necho testhost\n'  > "$work/bin/hostname"
printf '#!/bin/sh\nexit 1\n'         > "$work/bin/route"
printf '#!/bin/sh\nexit 1\n'         > "$work/bin/ifconfig"
chmod +x "$work"/bin/*

out=$(PATH="$work/bin:$PATH" bash "$script" 2>&1)
fail=0

case "$out" in
  *"up 1d 00:00"*) echo "ok   uptime comes from sec, not the usec that follows it" ;;
  *) echo "FAIL expected 'up 1d 00:00', got: $out"; fail=1 ;;
esac

[ "$fail" -eq 0 ] || { echo; echo "--- output ---"; printf '%s\n' "$out"; exit 1; }
echo "all checks passed"
