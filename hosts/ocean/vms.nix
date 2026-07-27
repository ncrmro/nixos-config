# Git-tracked libvirt inventory for Ocean.
{
  lib,
  pkgs,
  ...
}:
let
  windows = import ./vms/ncrmro-desktop-windows.nix;
  vms = {
    home-assistant = {
      name = "home-assistant";
      enable = true;
      description = "Home Assistant OS";
      uuid = "86d48b20-690f-4c51-9daa-7d6c436871c3";
      memoryMiB = 4096;
      vcpus = 2;
      disk = {
        device = "/dev/zvol/rpool/crypt/vms/home-assistant";
        bytes = 68719476736;
        managed = true;
        dataset = "rpool/crypt/vms/home-assistant";
        size = "64G";
        volblocksize = "16K";
      };
      network = {
        kind = "network";
        source = "default";
        mac = "52:54:00:67:8e:11";
      };
      secureBoot = false;
      tpm = false;
      autostart = false;
      startOnFirstEnable = false;
      migration = null;
    };
    ${windows.name} = windows;
  };

  retainedVolumes = {
    octoprint = {
      device = "/dev/zvol/rpool/crypt/vms/octoprint";
      reason = "Retained legacy 32 GiB zvol; no current Git-managed domain.";
    };
    udev = {
      device = "/dev/zvol/ocean/vms/udev";
      reason = "Retained legacy 1 TiB zvol pending owner identification.";
    };
  };

  xmlEscape =
    value:
    builtins.replaceStrings
      [
        "&"
        "<"
        ">"
        "'"
        "\""
      ]
      [
        "&amp;"
        "&lt;"
        "&gt;"
        "&apos;"
        "&quot;"
      ]
      value;

  mkDomainXml =
    vm:
    let
      windowsGuest = vm.migration != null;
      diskTarget = if windowsGuest then "sda" else "vda";
      diskBus = if windowsGuest then "sata" else "virtio";
      networkModel = if windowsGuest then "e1000e" else "virtio";
    in
    ''
      <domain type='kvm'>
        <name>${xmlEscape vm.name}</name>
        <uuid>${xmlEscape vm.uuid}</uuid>
        <description>${xmlEscape vm.description}</description>
        ${lib.optionalString windowsGuest ''
          <metadata>
            <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
              <libosinfo:os id="http://microsoft.com/win/11"/>
            </libosinfo:libosinfo>
          </metadata>
        ''}
        <memory unit='MiB'>${toString vm.memoryMiB}</memory>
        <currentMemory unit='MiB'>${toString vm.memoryMiB}</currentMemory>
        <vcpu placement='static'>${toString vm.vcpus}</vcpu>
        <os>
          <type arch='x86_64' machine='q35'>hvm</type>
          <loader readonly='yes' ${lib.optionalString vm.secureBoot "secure='yes' "}type='pflash'>/run/libvirt/nix-ovmf/${
            if vm.secureBoot then "OVMF_CODE.ms.fd" else "OVMF_CODE.fd"
          }</loader>
          <nvram template='/run/libvirt/nix-ovmf/${
            if vm.secureBoot then "OVMF_VARS.ms.fd" else "OVMF_VARS.fd"
          }'>/var/lib/libvirt/qemu/nvram/${xmlEscape vm.name}_VARS.fd</nvram>
          <boot dev='hd'/>
        </os>
        <features>
          <acpi/>
          <apic/>
          ${lib.optionalString windowsGuest ''
            <hyperv mode='custom'>
              <relaxed state='on'/>
              <vapic state='on'/>
              <spinlocks state='on' retries='8191'/>
            </hyperv>
            <vmport state='off'/>
          ''}
          ${lib.optionalString vm.secureBoot "<smm state='on'/>"}
        </features>
        <cpu mode='host-passthrough' check='none' migratable='on'/>
        <clock offset='${if windowsGuest then "localtime" else "utc"}'/>
        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>destroy</on_crash>
        <devices>
          <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>
          <disk type='block' device='disk'>
            <driver name='qemu' type='raw' cache='none' io='native' discard='unmap'/>
            <source dev='${xmlEscape vm.disk.device}'/>
            <target dev='${diskTarget}' bus='${diskBus}'/>
          </disk>
          ${lib.optionalString vm.tpm ''
            <tpm model='tpm-crb'>
              <backend type='emulator' version='2.0'/>
            </tpm>
          ''}
          <interface type='${xmlEscape vm.network.kind}'>
            <mac address='${xmlEscape vm.network.mac}'/>
            <source ${
              if vm.network.kind == "network" then "network" else "bridge"
            }='${xmlEscape vm.network.source}'/>
            <model type='${networkModel}'/>
          </interface>
          <controller type='sata' index='0'/>
          <controller type='virtio-serial' index='0'/>
          <channel type='spicevmc'>
            <target type='virtio' name='com.redhat.spice.0'/>
          </channel>
          <graphics type='spice' autoport='yes'>
            <listen type='none'/>
          </graphics>
          <video>
            <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
          </video>
          <sound model='ich9'/>
          <audio id='1' type='spice'/>
        </devices>
      </domain>
    '';

  enabledVms = lib.filterAttrs (_: vm: vm.enable) vms;
  managedDisks = lib.filterAttrs (_: vm: vm.enable && vm.disk.managed) vms;

  zvolCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (_: vm: ''
      if ! ${pkgs.zfs}/bin/zfs list -H ${lib.escapeShellArg vm.disk.dataset} >/dev/null 2>&1; then
        ${pkgs.zfs}/bin/zfs create -V ${lib.escapeShellArg vm.disk.size} \
          -b ${lib.escapeShellArg vm.disk.volblocksize} \
          -o refreservation=none \
          ${lib.escapeShellArg vm.disk.dataset}
      fi
    '') managedDisks
  );

  defineCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (_: vm: ''
      test -b ${lib.escapeShellArg vm.disk.device}
      ${pkgs.libvirt}/bin/virsh --connect qemu:///system define \
        /etc/keystone/libvirt/${lib.escapeShellArg "${vm.name}.xml"}
      ${
        if vm.autostart then
          "${pkgs.libvirt}/bin/virsh --connect qemu:///system autostart ${lib.escapeShellArg vm.name}"
        else
          "${pkgs.libvirt}/bin/virsh --connect qemu:///system autostart --disable ${lib.escapeShellArg vm.name}"
      }
      ${
        if vm.startOnFirstEnable then
          ''
            marker=/var/lib/keystone/vms/${lib.escapeShellArg vm.name}/started-once
            if [[ ! -e "$marker" ]]; then
              install -d -m 0750 "$(dirname "$marker")"
              state=$(${pkgs.libvirt}/bin/virsh --connect qemu:///system domstate ${lib.escapeShellArg vm.name})
              if [[ "$state" == "shut off" ]]; then
                ${pkgs.libvirt}/bin/virsh --connect qemu:///system start ${lib.escapeShellArg vm.name}
                state=$(${pkgs.libvirt}/bin/virsh --connect qemu:///system domstate ${lib.escapeShellArg vm.name})
              fi
              if [[ "$state" == "running" ]]; then
                touch "$marker"
              else
                echo "Refusing to mark ${vm.name} started-once while state is: $state" >&2
                exit 1
              fi
            fi
          ''
        else
          ""
      }
    '') enabledVms
  );
in
{
  keystone.os.physicalMigration.receiver.enable = true;
  keystone.os.hypervisor.defaultUri = "qemu:///system";

  assertions = lib.mapAttrsToList (_: vm: {
    assertion =
      !vm.enable
      || vm.migration == null
      || (
        vm.migration.bitlocker == "preserve"
        && vm.migration.sourceSha256 != ""
        && vm.migration.sourceSha256 == vm.migration.stagedSha256
        && vm.migration.promotedSnapshot != ""
      );
    message = "Enabled migrated VM ${vm.name} must preserve BitLocker and carry matching source/staged hashes plus a promoted snapshot.";
  }) vms;

  environment.etc =
    (lib.mapAttrs' (
      _: vm:
      lib.nameValuePair "keystone/libvirt/${vm.name}.xml" {
        mode = "0644";
        text = mkDomainXml vm;
      }
    ) vms)
    // {
      "keystone/libvirt/vms.json" = {
        mode = "0644";
        text = builtins.toJSON {
          inherit vms retainedVolumes;
        };
      };
      "keystone/libvirt/default-network.xml" = {
        mode = "0644";
        text = ''
          <network>
            <name>default</name>
            <forward mode='nat'/>
            <bridge name='virbr0' stp='on' delay='0'/>
            <ip address='192.168.122.1' netmask='255.255.255.0'>
              <dhcp>
                <range start='192.168.122.2' end='192.168.122.254'/>
              </dhcp>
            </ip>
          </network>
        '';
      };
    };

  systemd.services.keystone-vm-zvols = {
    description = "Ensure Git-managed VM zvols exist";
    wantedBy = [ "multi-user.target" ];
    before = [
      "libvirtd.service"
      "keystone-vm-registry.service"
    ];
    after = [ "zfs.target" ];
    requires = [ "zfs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      ${zvolCommands}
    '';
  };

  systemd.services.keystone-vm-registry = {
    description = "Define enabled Git-managed libvirt domains";
    wantedBy = [ "multi-user.target" ];
    after = [
      "libvirtd.service"
      "keystone-vm-zvols.service"
      "import-ocean.service"
    ];
    wants = [ "import-ocean.service" ];
    requires = [
      "libvirtd.service"
      "keystone-vm-zvols.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      if ! ${pkgs.libvirt}/bin/virsh --connect qemu:///system net-info default >/dev/null 2>&1; then
        ${pkgs.libvirt}/bin/virsh --connect qemu:///system net-define \
          /etc/keystone/libvirt/default-network.xml
      fi
      if ! ${pkgs.libvirt}/bin/virsh --connect qemu:///system net-info default \
        | ${pkgs.gnugrep}/bin/grep -Eq '^Active:[[:space:]]+yes$'; then
        ${pkgs.libvirt}/bin/virsh --connect qemu:///system net-start default
      fi
      ${pkgs.libvirt}/bin/virsh --connect qemu:///system net-autostart default
      ${defineCommands}
    '';
  };
}
