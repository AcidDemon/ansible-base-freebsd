# ansible-base-freebsd

![Ansible](https://img.shields.io/badge/Ansible-2.15%2B-EE0000?logo=ansible&logoColor=white)
![FreeBSD](https://img.shields.io/badge/FreeBSD-14%20%2F%2015-AB2B28?logo=freebsd&logoColor=white)
![pf](https://img.shields.io/badge/firewall-pf-AB2B28)

[![License: MIT](https://img.shields.io/github/license/AcidDemon/ansible-base-freebsd?color=blue)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/AcidDemon/ansible-base-freebsd)](https://github.com/AcidDemon/ansible-base-freebsd/commits/main)
[![Repo size](https://img.shields.io/github/repo-size/AcidDemon/ansible-base-freebsd)](https://github.com/AcidDemon/ansible-base-freebsd)
[![GitLab mirror](https://img.shields.io/badge/mirror-GitLab-FC6D26?logo=gitlab&logoColor=white)](https://git.inviziblenet.work/AcidDemon/ansible-base-freebsd)

Generic FreeBSD baseline: base OS, users, dotfiles, sysctl, chrony, ZFS boot environments,
and the **single-owner pf firewall** that apps extend by declaring `firewall_allow_tcp` /
`firewall_trust_iifnames` / `firewall_forward_policy`. base owns `/etc/pf.conf`, never
references an app, and never flushes its own tables.

## Run
    direnv allow   # or: export ANSIBLE_CONFIG=$PWD/ansible.cfg
    ansible-galaxy collection install -r requirements.yml
    ansible-playbook -i inventory/hosts.yml site.yml

## Firewall contract
`management_cidrs` (admin SSH sources), `firewall_allow_tcp` (public TCP),
`firewall_allow_tcp_mgmt` (mgmt-only TCP, default 22), `firewall_trust_iifnames`
(trusted input ifaces, e.g. `wg0`), `firewall_forward_policy`. base owns `/etc/pf.conf`;
sshguard and crowdsec own their own pf tables.

For rules this template cannot express (`rdr`, `nat`, per-host filters), declare
`firewall_anchors: [name]`. base emits the `nat-anchor`/`rdr-anchor`/`anchor` lines plus
`load anchor "name" from "/etc/pf.anchors/name"`, and creates that file empty if it does
not exist. The app layer owns its contents; base still never references an app. Filter
anchors are placed last, so app rules are evaluated after base's own.

## Nightly reports
`base_updates` owns the `periodic.conf` keys that decide what reaches your inbox. It sets
`security_show_success=NO`, so a security check that found nothing prints nothing at all.
That is what `periodic(8)` intends by exit status 0, and it is why the default setting
produces headings with no body. `999.clean-note` runs last and closes the mail with one
line saying the checks not listed above came back clean.

A drop-in of your own in `/usr/local/etc/periodic/security` must therefore exit 1 when it
has routine output worth reading, or 3 when it found something that must not be masked.
Exit 0 means "nothing to say" and will be swallowed.

The daily run keeps `daily_show_success` at its default, because its exit-0 scripts print
`df -h`, `zpool list` and `netstat -i`. Only `daily_clean_preserve_enable`,
`daily_clean_msgs_enable` and `daily_clean_rwho_enable` are turned off: vi recovery files,
`msgs(1)` announcements and `rwhod` are unused on a modern box, and each one printed a
heading and nothing else every night.
