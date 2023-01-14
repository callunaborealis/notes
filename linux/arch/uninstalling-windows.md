# Uninstall Windows and expanding Windows EFI Partition

## Unregister your retail Windows licence

In your existing copy of Windows, open an elevated Command Prompt session:

```bat
slmgr /upk
```

## Re-partition your primary drive

- Load the Arch installation media
- `fdisk /dev/your_main_drive`
- Create a new empty GPT partition table. Over multiple updates of both Windows and Arch Linux, there might be issues where the EFI partition of 100MB may be insufficient. A recommendation of 1G may be needed

```
1G EFI System (fdisk t Code 1)
```

- Once GPT table has been written, format the new partition.

```sh
# Replace efi_partition with nvme0n1p1 or sda1 etc
mkfs.fat -F 32 /dev/efi_partition
```

- Reboot into the Windows installation media and install Windows using a custom set up
- Confirm that "Drive 0 Partition 1" is indeed 1021.0 MB (e.g. (1 GB))
- Create a new partition which will be designated as your primary drive
- Set to [UTC time in Windows](./using-universal-time.md).

## References

- https://winaero.com/how-to-deactivate-windows-10-and-change-the-product-key/
