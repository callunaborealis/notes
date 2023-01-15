# Initialising partitions

## Pre-requisites

- [Created and booted into installation media](./create-installation-media.md)

## Creating partition tables with `fdisk`

- `fdisk -l`: Lists all the partitions detected
- `fdisk /dev/sda` / `fdisk /dev/nvme1n1` : Opens the interactive fdisk window
- Use `m` to list out the possible actions. Usually `n` to create new partitions, and `w` to write the partition table once it is created. `83` for Linux, `+1T` for 1 TB for the second sector
- Once done, hit `w`, then check `fdisk -l` to see the new partition table

## Creating a UEFI file system

```sh
# Create some kind of EFI partition
mkfs.fat -F32 /dev/shared_efi_part
mkfs.fat -F32 /dev/windows_recovery_part
mkfs.fat -F32 /dev/xbootldr_part
# To create a Linux root / home partition
mkfs.ext4 /dev/root_part
# Create a swap drive
mkswap -L "swap" /dev/swap_part
```

## Next steps

- [Installing Arch Linux for a Windows Dual Boot](./installing-windows-first-dual-boot.md)

## References

- https://wiki.archlinux.org/title/Fdisk