# Using GRUB for Arch

## UEFI / GPT (Windows Dual Boot)

### Prerequisites

- [Setting up UEFI GPT](./setting-up-uefi-gpt.md)

```bash
# root@archiso
arch-chroot /mnt
pacman -S grub efibootmgr os-prober
exit
```

Mount the drives, then run `bootctl` to create the boot entries.

```bash
# root@archiso
mount --mkdir /dev/root_part /mnt
mount --mkdir /dev/windowsbootloader_part /mnt/efi
mount --mkdir /dev/xbootldr_part /mnt/boot
# Note: You can remove --mkdir flag on subsequent re-mountings
swapon /dev/swap_part
# Verify all mounted
lsblk
bootctl --esp-path=/mnt/efi --boot-path=/mnt/boot install
# Verify "Linux Boot Manager" is added as an entry to the boot order
efibootmgr
arch-chroot /mnt
exit
```

Once done, proceed with [installing GRUB](https://wiki.archlinux.org/title/GRUB#Installation). We are assuming you are using an x86_64 system (64-bit).

```bash
# root@archiso
# Not recommended but if for some reason, you need to install it in the installation environment, add the
# --boot-directory flag pointing to the XBOOTLDR partition
# grub-install --target=x86_64-efi --boot-directory=/mnt/boot --efi-directory=/mnt/efi --bootloader-id=GRUB
arch-chroot /mnt
# Installs grub in /mnt/boot/grub
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
# There should be no errors
exit
```

Next, we generate the GRUB configuration file via `grub-mkconfig`.

```bash
# root@archiso
arch-chroot /mnt
vim /etc/default/grub
```
```ini
# /etc/default/grub
# Change from 5 seconds (too short) to 60 seconds to choose the partition to load
GRUB_TIMEOUT=60
# Add splash (and nvidia-drm.modeset=1 required for plasma-wayland-session)
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
GRUB_DISABLE_OS_PROBER=false
```
```bash
os-prober
```

Hopefully it prints out:

```bash
/dev/windows_efi_part/EFI/Microsoft/Boot/bootmgfw.efi:Windows Boot Manager:Windows:efi
```
If we are not able to detect Windows, that is fine. `os-prober` usually will not be able to detect Windows within the Arch installation media.

Run `grub-mkconfig` anyway so you can use GRUB to enter your newly created Arch partition to check `os-prober` again.

```bash
grub-mkconfig -o /boot/grub/grub.cfg
exit
```

Now we can try to reboot the newly created partition (via BIOS) as root and check `os-prober` while inside the newly created Arch Linux partition.


```bash
# root@archiso
reboot
# Log in as root Arch Linux on your target drive.
# root@new-arch-partition
os-prober
# Now that we are @new-arch-partition and not @archiso, hopefully it will print out:
# /dev/windows_efi_part/EFI/Microsoft/Boot/bootmgfw.efi:Windows Boot Manager:Windows:efi
grub-mkconfig -o /boot/grub/grub.cfg
```

Once done, you will be able to boot into the newly created Arch partition independently.

## BIOS / MBR (Arch Single Boot on older systems)

Requires a 1-2 MB BIOS boot partition as the first partition. Especially for older machines.

```bash
# root@archiso
arch-chroot /mnt
pacman -S grub
# Where /dev/sdX is the whole drive and not the partition, e.g. /dev/sda instead of /dev/sda4
grub-install --target=i386-pc /dev/sdX
grub-mkconfig -o /boot/grub/grub.cfg
exit
```

## Next steps

- [Back to installing Windows First Dual Boot](./installing-windows-first-dual-boot.md#setting-up-the-grub-bootloader)
