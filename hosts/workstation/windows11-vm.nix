{
  config,
  pkgs,
  lib,
  ...
}: {
  # Add user to the disk group to allow access to the NVMe device
  users.users.ncrmro.extraGroups = ["disk"];

  # Create udev rule to set proper permissions for the Windows NVMe disk
  services.udev.extraRules = ''
    # Allow libvirt access to the Windows 11 NVMe disk (nvme1n1)
    SUBSYSTEM=="block", KERNEL=="nvme1n1", GROUP="disk", MODE="0660"
    SUBSYSTEM=="block", KERNEL=="nvme1n1p*", GROUP="disk", MODE="0660"
  '';

  # Ensure the libvirtd service has proper access
  systemd.services.libvirtd = {
    serviceConfig = {
      SupplementaryGroups = ["disk"];
    };
  };

  # Create the Windows 11 VM XML definition
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/qemu/nvram 0755 root root -"
  ];

  # The VM can be managed through virt-manager or virsh
  # After nixos-rebuild switch, you must run:
  # virsh define /etc/libvirt/qemu/windows11.xml
  # This imports/updates the VM configuration in libvirt

  environment.etc."libvirt/qemu/windows11.xml" = {
    mode = "0644";
    text = ''
      <domain type='kvm'>
        <name>windows11</name>
        <metadata>
          <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
            <libosinfo:os id="http://microsoft.com/win/11"/>
          </libosinfo:libosinfo>
        </metadata>
        <memory unit='GiB'>16</memory>
        <currentMemory unit='GiB'>16</currentMemory>
        <vcpu placement='static'>8</vcpu>
        <os>
          <type arch='x86_64' machine='pc-q35-9.0'>hvm</type>
          <loader readonly='yes' secure='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.ms.fd</loader>
          <nvram template='/run/libvirt/nix-ovmf/OVMF_VARS.ms.fd'>/var/lib/libvirt/qemu/nvram/windows11_VARS.fd</nvram>
          <boot dev='hd'/>
        </os>
        <features>
          <acpi/>
          <apic/>
          <hyperv mode='custom'>
            <relaxed state='on'/>
            <vapic state='on'/>
            <spinlocks state='on' retries='8191'/>
            <vendor_id state='on' value='1234567890ab'/>
          </hyperv>
          <vmport state='off'/>
          <smm state='on'/>
        </features>
        <cpu mode='host-passthrough' check='none' migratable='on'>
          <topology sockets='1' dies='1' cores='4' threads='2'/>
        </cpu>
        <clock offset='localtime'>
          <timer name='rtc' tickpolicy='catchup'/>
          <timer name='pit' tickpolicy='delay'/>
          <timer name='hpet' present='no'/>
          <timer name='hypervclock' present='yes'/>
        </clock>
        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>destroy</on_crash>
        <pm>
          <suspend-to-mem enabled='no'/>
          <suspend-to-disk enabled='no'/>
        </pm>
        <devices>
          <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>

          <!-- Pass through the entire Windows NVMe disk -->
          <disk type='block' device='disk'>
            <driver name='qemu' type='raw' cache='none' io='native'/>
            <source dev='/dev/nvme1n1'/>
            <target dev='vda' bus='virtio'/>
            <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
          </disk>

          <!-- TPM 2.0 Device -->
          <tpm model='tpm-crb'>
            <backend type='emulator' version='2.0'/>
          </tpm>

          <!-- Network -->
          <interface type='network'>
            <source network='default'/>
            <model type='virtio'/>
            <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
          </interface>

          <!-- Graphics -->
          <graphics type='spice' autoport='yes'>
            <listen type='address'/>
            <image compression='off'/>
          </graphics>
          <video>
            <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
          </video>

          <!-- USB Controllers -->
          <controller type='usb' index='0' model='qemu-xhci' ports='15'>
            <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
          </controller>

          <!-- Sound -->
          <sound model='ich9'>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
          </sound>
          <audio id='1' type='spice'/>

          <!-- PCI Controllers -->
          <controller type='pci' index='0' model='pcie-root'/>
          <controller type='pci' index='1' model='pcie-root-port'>
            <model name='pcie-root-port'/>
            <target chassis='1' port='0x10'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
          </controller>
          <controller type='pci' index='2' model='pcie-root-port'>
            <model name='pcie-root-port'/>
            <target chassis='2' port='0x11'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
          </controller>
          <controller type='pci' index='3' model='pcie-root-port'>
            <model name='pcie-root-port'/>
            <target chassis='3' port='0x12'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
          </controller>
          <controller type='pci' index='4' model='pcie-root-port'>
            <model name='pcie-root-port'/>
            <target chassis='4' port='0x13'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
          </controller>
          <controller type='pci' index='5' model='pcie-root-port'>
            <model name='pcie-root-port'/>
            <target chassis='5' port='0x14'/>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
          </controller>
          <controller type='sata' index='0'>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
          </controller>
          <controller type='virtio-serial' index='0'>
            <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
          </controller>

          <!-- Serial console -->
          <serial type='pty'>
            <target type='isa-serial' port='0'>
              <model name='isa-serial'/>
            </target>
          </serial>
          <console type='pty'>
            <target type='serial' port='0'/>
          </console>

          <!-- Spice agent -->
          <channel type='spicevmc'>
            <target type='virtio' name='com.redhat.spice.0'/>
            <address type='virtio-serial' controller='0' bus='0' port='1'/>
          </channel>

          <!-- Memory balloon -->
          <memballoon model='virtio'>
            <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
          </memballoon>
        </devices>
      </domain>
    '';
  };
}
