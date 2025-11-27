# VM configuration for ocean host
# Creates thinly provisioned ZFS zvols and VM definitions
{
  pkgs,
  lib,
  ...
}: let
  # ZFS parent dataset for all VMs
  vmsDataset = "rpool/crypt/vms";

  # VM definitions
  vms = {
    home-assistant = {
      size = "64G";
      memory = 4; # GB
      vcpus = 2;
      description = "Home Assistant OS";
    };
    octoprint = {
      size = "32G";
      memory = 2; # GB
      vcpus = 2;
      description = "OctoPrint for 3D printer management";
    };
  };

  # Generate zvol creation commands
  zvolCommands = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: cfg: ''
      if ! ${pkgs.zfs}/bin/zfs list ${vmsDataset}/${name} &>/dev/null; then
        echo "Creating zvol ${vmsDataset}/${name} (${cfg.size}, thin provisioned)"
        ${pkgs.zfs}/bin/zfs create -V ${cfg.size} \
          -o volblocksize=16K \
          -o refreservation=none \
          ${vmsDataset}/${name}
      else
        echo "zvol ${vmsDataset}/${name} already exists"
      fi
    '')
    vms);
in {
  imports = [
    ../common/optional/libvirt-server.nix
  ];

  # Systemd service to ensure ZFS parent dataset and zvols exist
  systemd.services.ensure-vm-zvols = {
    description = "Ensure ZFS zvols exist for VMs";
    wantedBy = ["multi-user.target"];
    before = ["libvirtd.service"];
    after = ["zfs.target"];
    requires = ["zfs.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail

      # Create parent dataset if it doesn't exist
      if ! ${pkgs.zfs}/bin/zfs list ${vmsDataset} &>/dev/null; then
        echo "Creating parent dataset ${vmsDataset}"
        ${pkgs.zfs}/bin/zfs create -o mountpoint=none ${vmsDataset}
      fi

      # Create zvols for each VM
      ${zvolCommands}

      echo "VM zvols ready"
    '';
  };

  # Ensure libvirtd starts after zvols are ready
  systemd.services.libvirtd = {
    after = ["ensure-vm-zvols.service"];
    requires = ["ensure-vm-zvols.service"];
  };

  # VM XML definitions - these can be imported with: virsh define /etc/libvirt/qemu/<name>.xml
  environment.etc."libvirt/qemu/home-assistant.xml" = {
    mode = "0644";
    text = ''
      <domain type='kvm'>
        <name>home-assistant</name>
        <description>Home Assistant OS VM</description>
        <memory unit='GiB'>${toString vms.home-assistant.memory}</memory>
        <vcpu placement='static'>${toString vms.home-assistant.vcpus}</vcpu>
        <os>
          <type arch='x86_64' machine='q35'>hvm</type>
          <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
          <nvram template='/run/libvirt/nix-ovmf/OVMF_VARS.fd'>/var/lib/libvirt/qemu/nvram/home-assistant_VARS.fd</nvram>
          <boot dev='cdrom'/>
          <boot dev='hd'/>
        </os>
        <features>
          <acpi/>
          <apic/>
        </features>
        <cpu mode='host-passthrough'/>
        <clock offset='utc'/>
        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>destroy</on_crash>
        <devices>
          <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>
          <disk type='block' device='disk'>
            <driver name='qemu' type='raw' cache='none' io='native' discard='unmap'/>
            <source dev='/dev/zvol/${vmsDataset}/home-assistant'/>
            <target dev='vda' bus='virtio'/>
          </disk>
          <disk type='file' device='cdrom'>
            <driver name='qemu' type='raw'/>
            <source file='/var/lib/libvirt/isos/haos.img'/>
            <target dev='sda' bus='sata'/>
            <readonly/>
          </disk>
          <interface type='network'>
            <source network='default'/>
            <model type='virtio'/>
          </interface>
          <console type='pty'/>
          <channel type='unix'>
            <target type='virtio' name='org.qemu.guest_agent.0'/>
          </channel>
          <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'/>
          <video>
            <model type='virtio' heads='1'/>
          </video>
        </devices>
      </domain>
    '';
  };

  environment.etc."libvirt/qemu/octoprint.xml" = {
    mode = "0644";
    text = ''
      <domain type='kvm'>
        <name>octoprint</name>
        <description>OctoPrint VM for 3D printer management</description>
        <memory unit='GiB'>${toString vms.octoprint.memory}</memory>
        <vcpu placement='static'>${toString vms.octoprint.vcpus}</vcpu>
        <os>
          <type arch='x86_64' machine='q35'>hvm</type>
          <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
          <nvram template='/run/libvirt/nix-ovmf/OVMF_VARS.fd'>/var/lib/libvirt/qemu/nvram/octoprint_VARS.fd</nvram>
          <boot dev='cdrom'/>
          <boot dev='hd'/>
        </os>
        <features>
          <acpi/>
          <apic/>
        </features>
        <cpu mode='host-passthrough'/>
        <clock offset='utc'/>
        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>destroy</on_crash>
        <devices>
          <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>
          <disk type='block' device='disk'>
            <driver name='qemu' type='raw' cache='none' io='native' discard='unmap'/>
            <source dev='/dev/zvol/${vmsDataset}/octoprint'/>
            <target dev='vda' bus='virtio'/>
          </disk>
          <disk type='file' device='cdrom'>
            <driver name='qemu' type='raw'/>
            <source file='/var/lib/libvirt/isos/octoprint.iso'/>
            <target dev='sda' bus='sata'/>
            <readonly/>
          </disk>
          <interface type='network'>
            <source network='default'/>
            <model type='virtio'/>
          </interface>
          <console type='pty'/>
          <channel type='unix'>
            <target type='virtio' name='org.qemu.guest_agent.0'/>
          </channel>
          <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'/>
          <video>
            <model type='virtio' heads='1'/>
          </video>
        </devices>
      </domain>
    '';
  };
}
