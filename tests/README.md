# Testing base_freebsd

Production target is **FreeBSD 15**. No libvirt FreeBSD-15 Vagrant box is published on
Vagrant Cloud yet, so the default box is `generic/freebsd14`. The collection is
version-agnostic (the `os_base` assert checks `os_family == 'FreeBSD'`; pf, sysrc, pkgng,
bectl and the sysctl MIB behave identically on 14 and 15), so a 14 box validates the
automation. Swap to a 15 box when you have one:

```sh
FREEBSD_BOX=generic/freebsd15 vagrant up          # when roboxes publishes it
FREEBSD_BOX=FreeBSD-15.0-RELEASE-amd64 vagrant up # a locally packer-built box
```

## Spin up + provision (libvirt, like the debian/suse repos)

```sh
vagrant up            # boots the box AND runs playbooks/site.yml via the ansible provisioner
vagrant provision     # re-run the playbook (use for the idempotence check)
vagrant ssh           # log in to inspect
vagrant destroy -f    # tear down
```

The `vagrant-libvirt` management network is `192.168.121.0/24`; the Vagrantfile pins
`management_cidrs` to it so `base_firewall`'s lockout guard passes. Override with
`FREEBSD_MGMT_CIDR=...` if your libvirt network differs.

## Smoke assertions (run inside `vagrant ssh`)

```sh
pfctl -n -f /etc/pf.conf && echo "pf.conf parses"
pfctl -s info | grep -q 'Status: Enabled' && echo "pf enabled"
pfctl -s Tables | grep -E 'management|sshguard|crowdsec-blacklists'   # base + sibling tables
sysrc -n pf_enable pflog_enable chronyd_enable
service chronyd status && chronyc tracking | head -3
sysctl security.bsd.see_other_uids net.inet.tcp.blackhole
id acid | grep -q wheel && echo "admin in wheel"
sudo -n -l -U ansible | grep -q NOPASSWD && echo "deploy nopasswd sudo"
crontab -l -u root | grep freebsd-auto-update
bectl list                     # on ZFS root: an ansible-preupdate-* BE exists
ls -l ~/.bashrc ~/.tmux.conf ~/.vimrc ~/.gitconfig
```

## Idempotence

```sh
vagrant provision 2>&1 | tail -20    # PLAY RECAP: changed=0 ideal
```
Only `changed_when: false` probe tasks (pf info, bectl list) may report work; nothing else
should be `changed` on a second run.
