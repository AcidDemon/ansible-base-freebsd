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
