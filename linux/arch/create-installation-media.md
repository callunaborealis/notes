# Downloading and Installing

- [Download](https://archlinux.org/download/) Arch Linux distro, recommended via a torrent to prevent interception (I might be paranoid though)

```txt
Downloads
> archlinux-2022.04.05-x86_64.iso
```

- [Verify](https://wiki.archlinux.org/title/Installation_guide#Verify_signature) the install via GPG. Install via your package manager if need be

```txt
Downloads
> archlinux-2022.04.05-x86_64.iso
> archlinux-2022.04.05-x86_64.iso.sig # Signature file
```

```bash
$ gpg --keyserver-options auto-key-retrieve --verify archlinux-version-x86_64.iso.sig

gpg: assuming signed data in 'archlinux-2022.04.05-x86_64.iso'
gpg: Signature made Wed Apr  6 00:05:57 2022 +08
gpg:                using RSA key 4AA4767BBC9C4B1D18AE28B77F2D434B9741E8AC
gpg:                issuer "pierre@archlinux.de"
gpg: Good signature from "Pierre Schmitz <pierre@archlinux.de>" [unknown]
gpg: WARNING: The key\'s User ID is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 4AA4 767B BC9C 4B1D 18AE  28B7 7F2D 434B 9741 E8AC
```
- Compare key fingerprint with the developer's signature on the Arch Linux site: https://archlinux.org/people/developers/

- Now find the name of the USB disk (i.e. `df -h` for macOS). We are going to use `dd`. See https://wiki.archlinux.org/title/USB_flash_installation_medium#Using_macOS_dd
- Remember to add FAT32 / MS-DOS (FAT) targeting the parent drive (and not just the partition). Using partitions did not work in my experience

```bash
# macOS
df -h # Find disk name / partition name to write bootable drive

# If resource busy, unmount the disk first
sudo diskutil unmount /dev/disk2

sudo dd if=/Users/calluna/Downloads/archlinux-2022.04.05-x86_64.iso of=/dev/disk2 bs=1m
```

- Use CTRL+T to check
- Now plug in your USB drive via any USB slot (not BIOS).
- Restart your PC and bring up BIOS boot loader (usually F2 when you see the default splash screen).
- Find the boot menu and load the UEFI BIOS which should be available as a boot option and enter

## Next steps

- [Installing Arch Linux for a Windows Dual Boot](./installing-windows-first-dual-boot.md)
- [Initialising partitions](./initialising-partitions.md)
- [Uninstalling Arch Linux for a Windows Dual Boot](./uninstalling-windows-first-dual-boot.md)

## References

- [Using macOS dd](https://wiki.archlinux.org/title/USB_flash_installation_medium#Using_macOS_dd)
