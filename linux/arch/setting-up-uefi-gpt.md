# Setting up UEFI GPT before Arch install on a Windows First Dual Boot PC

## Pre-requisites

- [Arch installation medium](./create-installation-media.md)
- Windows is already installed and exists as the only OS on the hard drive

## Steps

### Prepare space behind Windows main partition if you have all sectors in the hard drive

Run GWMI on PowerShell to load the partition UUIDs so you can tell which partition is the one you want to install Arch Linux on.

<br />

```powershell
GWMI -namespace root\cimv2 -class win32_volume | FL -property Label,DriveLetter,DeviceID,SystemVolume,Capacity,Freespace
```

Use Windows to shrink `C:\` such that you will have enough space for installing Arch.

### Set up UEFI/GPT layout for a single hard drive

See how to [set up partitions here](./initialising-partitions.md).

- around 1G for Linux extended boot (Code 136). Why 1G? By around mid-2025, even with compression enabled set via `mkinitcpio`, we still need around **500M** for the initial RAM file system (`initramfs`), and another **500M** for the backup `initramfs`.
  - Because the Windows EFI boot loader is only 100MB, it's too small to add other OS boot loaders. So we need an [extendible boot loader as a partition](https://wiki.archlinux.org/title/Systemd-boot#Installation_using_XBOOTLDR) to allow a dual boot.
- around 8GB for Linux swap (Code 19) - This was a personal choice as I have 32GB total RAM, and this was recommended by a [poll of Arch users](https://opensource.com/article/19/2/swap-space-poll). A swap drive is also optional if you rather have swap files instead of swap drives.
- remaining for the Linux root partition x86-64 (Code 23), where packages will be installed
- home partition (if ever needed), for personal files independent of OS

### Sample ideal partition table

```
Disklabel type: gpt
Device            Size    Type
/dev/nvme0n1p1    1G      EFI System
/dev/nvme0n1p2    16M     Microsoft reserved
/dev/nvme0n1p3    1G      Microsoft basic data
/dev/nvme0n1p4    1G      Microsoft recovery environment
/dev/nvme0n1p5    1G      Microsoft recovery environment
/dev/nvme0n1p6    1G      Linux extended boot
/dev/nvme0n1p7    8G      Linux swap
/dev/nvme0n1p8    1T      Linux root (x86-64)    
```

## Next steps

- [Install Arch on a Windows First Dual Boot PC](./installing-windows-first-dual-boot.md)