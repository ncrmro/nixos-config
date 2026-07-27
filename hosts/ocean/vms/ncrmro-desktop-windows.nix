# Generated seed. The physical migration script owns subsequent changes.
{
  name = "ncrmro-desktop-windows";
  enable = false;
  description = "Windows desktop adopted from a physical BitLocker NVMe";
  uuid = "986197ab-e314-4ff8-9703-ae7b8a192663";
  memoryMiB = 16384;
  vcpus = 8;
  disk = {
    device = "/dev/zvol/ocean/vms/ncrmro-desktop-windows";
    bytes = 2000398934016;
    managed = false;
  };
  network = {
    kind = "network";
    source = "default";
    mac = "52:54:00:ac:4b:9e";
  };
  secureBoot = true;
  tpm = true;
  autostart = false;
  startOnFirstEnable = true;
  migration = {
    bitlocker = "preserve";
    sourceById = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S6B0NJ0RB17772A";
    sourceSerial = "S6B0NJ0RB17772A";
    sourceBytes = 2000398934016;
    sourceSha256 = "";
    stagedSha256 = "";
    promotedSnapshot = "";
  };
}
