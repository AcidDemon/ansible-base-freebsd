# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# libvirt/KVM test box for acidnetworks.base_freebsd.
#
# No libvirt FreeBSD-15 box is published yet, so the default is generic/freebsd14. The
# collection is version-agnostic (pf/sysrc/pkgng/bectl/sysctl MIB are identical on 14 and
# 15), so a 14 box validates the automation. Production is 15. Swap once available:
#     FREEBSD_BOX=generic/freebsd15 vagrant up
#     FREEBSD_BOX=FreeBSD-15.0-RELEASE-amd64 vagrant up  # locally-built packer box
#
# vagrant-libvirt's mgmt network defaults to 192.168.121.0/24. That subnet must be in
# management_cidrs or base_firewall's lockout guard refuses. Override for a different net:
#     FREEBSD_MGMT_CIDR=192.168.50.0/24 vagrant up

FREEBSD_BOX  = ENV.fetch("FREEBSD_BOX", "generic/freebsd14")
MGMT_CIDR    = ENV.fetch("FREEBSD_MGMT_CIDR", "192.168.121.0/24")

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  # FreeBSD has no vboxsf and rsync needs the rsync pkg. Disable the share, the
  # collection is installed by the ansible provisioner, not from /vagrant.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.define "freebsd" do |fb|
    fb.vm.box = FREEBSD_BOX
    fb.vm.hostname = "fbsd-test"
    fb.vm.guest = :freebsd
    fb.ssh.shell = "/bin/sh"

    fb.vm.provider :libvirt do |libvirt|
      libvirt.driver = "kvm"
      libvirt.uri = "qemu:///system"
      libvirt.memory = "2048"
      libvirt.cpus = 2
    end

    # site.yml's bootstrap play installs python3 via raw, so a box without python still
    # provisions. base_hosts is the group site.yml targets.
    fb.vm.provision "ansible" do |a|
      a.playbook = "playbooks/site.yml"
      a.compatibility_mode = "2.0"
      a.groups = { "base_hosts" => ["freebsd"] }
      # The provisioner uses vagrant's own generated inventory, not inventory/group_vars,
      # so the contract vars must be passed here. mgmt CIDR is pinned to the vagrant
      # network so base_firewall's lockout guard passes.
      a.extra_vars = {
        "management_cidrs" => [MGMT_CIDR],
        "firewall_allow_tcp_mgmt" => [22],
        "target_users" => [
          { "name" => "root", "home" => "/root", "group" => "wheel" },
          { "name" => "acid", "home" => "/home/acid", "group" => "acid" },
        ],
        # vagrant's inventory_dir isn't the repo, so point key discovery at files/ssh
        # (empty by default, so the key task skips cleanly).
        "base_users_ssh_dir" => "#{__dir__}/files/ssh",
      }
    end
  end
end
