# Mounting an old Ubuntu disk (LUKS + LVM)

Adjust device identifiers to your disk.

```bash
sudo cryptsetup luksOpen /dev/disk/by-id/ata-Samsung_SSD_980_PRO_2TB_S6B0NL0W127373V-part3 oldroot
sudo vgscan
mkdir -p /media/oldroot
sudo mount /dev/mapper/vgubuntu-root /media/oldroot/
```

When finished:
```bash
sudo umount /media/oldroot
sudo vgexport vgubuntu
sudo cryptsetup luksClose oldroot
```