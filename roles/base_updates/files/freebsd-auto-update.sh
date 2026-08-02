#!/bin/sh
# Managed by Ansible. Unattended base + pkg updates. Locked packages are skipped.
set -u
log() { logger -t freebsd-auto-update "$*"; echo "[freebsd-auto-update] $*"; }

export PAGER=cat
log "fetching base security updates"
env ASSUME_ALWAYS_YES=yes freebsd-update --not-running-from-cron fetch install || log "freebsd-update rc=$?"

log "upgrading packages"
env ASSUME_ALWAYS_YES=yes pkg upgrade -y || log "pkg upgrade rc=$?"

log "done (no auto-reboot by policy)"
