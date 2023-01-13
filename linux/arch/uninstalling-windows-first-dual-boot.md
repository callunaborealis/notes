# Re-installing Arch on a Windows First Dual Boot PC

## Pre-requisites

- Use the [Arch installation media](./create-installation-media.md) to boot the faulty Arch drive

## Steps

```bash
# root@archiso
# Nice to refer to all the available disks and partitions
fdisk -l
# List all available partitions and where they are mounted (if mounted)
lsblk
mount /dev/linux_root_part /mnt
mount /dev/windows_efi_part /mnt/efi # If any
mount /dev/xbootldr_part /mnt/boot
swapon /dev/linux_swap_part
```

Plug in a removable drive and copy all existing user files you want to salvage before you do the wipe.

```bash
# root@archiso
# Work from inside the "faulty Arch drive" if possible. If not, mount it in the installation media directory
arch-chroot /mnt
# Using /media here just to use a common convention, you can mount the drive wherever you like on your drive
mkdir /media && mkdir /media/DRIVE_NAME
# Find the removable drive partition (assuming it's /dev/sdb1)
fdisk -l
mount /dev/sdb1 /media/DRIVE_NAME
# Just an example
cp -r /home/YOU/Pictures /media/DRIVE_NAME/Pictures
# Once done, unmount it all. Use lsblk to check what is currently mounted
exit
umount /mnt/efi
umount /mnt/boot
umount /mnt
swapoff -a
```

If you have GRUB, delete the entry using `efibootmgr` so we can regenerate it later.

```bash
# root@archiso
efibootmgr
# > This lists the boot order

efibootmgr # To list options
# Where 000X is the boot order value of "Linux Boot Manager" that we will replace later
efibootmgr --boot-num 000X --delete-bootnum
# Where 000X is the boot order value of "GRUB" that we will replace later
efibootmgr --boot-num 000Y --delete-bootnum
```

Caution before proceeding. You will not be able to go back after executing the following scripts. Next steps: Reformat the faulty extended boot, swap and root drives.

If you want to reallocate your partitions instead, read [how to do so here](./initialising-partitions.md).

```bash
# root@archiso
swapoff -a
# POINT OF NO RETURN! Do not proceed unless you know what you are doing.
mkfs.ext4 /dev/root_part
mkfs.fat -F 32 /dev/xbootldr_part
mkswap -L "swap" /dev/swap_part
# To check if your root linux drive has been clearly wiped, you
# realise you will not be able to arch-chroot into the root drive now
```

We don't need to make changes to the partitions since we are just doing a clean re-install.

## Next steps


- [Installing Arch Linux on a Windows PC](./installing-windows-first-dual-boot.md)