#!/usr/local/bin/bash
set -euo pipefail

host="$(hostname -s 2>/dev/null || hostname)"

ip="$(route -n get 1.1.1.1 2>/dev/null | awk '/interface:/{i=$2} END{if(i) system("ifconfig "i" inet | awk \x27/inet /{print $2; exit}\x27")}' || true)"
[[ -n "${ip:-}" ]] || ip="$(ifconfig 2>/dev/null | awk '/inet /{print $2; exit}' || true)"

load="$(sysctl -n vm.loadavg 2>/dev/null | tr -d '{}' | awk '{print $1" "$2" "$3}' || echo '?')"

mem="$(
  total=$(sysctl -n hw.physmem 2>/dev/null || echo 0)
  pagesize=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
  free_pages=$(sysctl -n vm.stats.vm.v_free_count 2>/dev/null || echo 0)
  inact_pages=$(sysctl -n vm.stats.vm.v_inactive_count 2>/dev/null || echo 0)
  avail=$(( (free_pages + inact_pages) * pagesize ))
  if [[ "$total" -gt 0 ]]; then awk -v t="$total" -v a="$avail" 'BEGIN{printf "%.0f%%", (t-a)*100/t}'; else echo '?'; fi
)"

upt="$(
  # Anchored, because sysctl prints "{ sec = N, usec = M }" and a leading .*
  # is greedy: it runs past the first "sec = " and matches the one inside
  # "usec = " instead, so this read the microseconds and every box reported an
  # uptime counted from the epoch.
  boot=$(sysctl -n kern.boottime 2>/dev/null | sed -n 's/^{ *sec = \([0-9]*\).*/\1/p')
  now=$(date +%s)
  if [[ -n "$boot" ]]; then s=$((now-boot)); d=$((s/86400)); s=$((s%86400)); h=$((s/3600)); m=$(((s%3600)/60));
    if [[ "$d" -gt 0 ]]; then printf "%dd %02d:%02d" "$d" "$h" "$m"; else printf "%02d:%02d" "$h" "$m"; fi
  else echo '?'; fi
)"

dt="$(date '+%Y-%m-%d %H:%M')"
printf "%s%s | load %s | mem %s | up %s | %s" "$host" "${ip:+ $ip}" "$load" "$mem" "$upt" "$dt"
