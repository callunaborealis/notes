# Setting up Arch Linux on a Windows First PC (with an Nvidia GPU and AMD CPU)

## Pre-requisites

- [Created and booted into installation media](./create-installation-media.md)
- [1G EFI is created as the first drive](./initialising-partitions.md) with [an existing Windows 11 first set up](./uninstalling-windows.md)
- [UEFI/GPT is set up with the new partitions formatted into a extendable boot loader drive, swap drive and root drive](./setting-up-uefi-gpt.md). If not, [set up partitions first](./initialising-partitions.md)

## Steps

Mount the root drive where Arch will be installed.

```bash
# root@archiso
mount --mkdir /dev/root_part /mnt
swapon /dev/swap_part
# Verify root partition mounted
lsblk
```

Install Arch onto `/mnt`.

```bash
# root@archiso
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
more /mnt/etc/fstab # Verify file created with correct entries
```

Now we can enter the newly initialised `/mnt` and change some default configurations.

Ensure [universal time is also used](./using-universal-time.md) if you have an existing Windows first partition, in order to prevent mismatched time zone expectations between partitions.

```bash
# root@archiso
# We ensure that time and date is set correctly before we change `/mnt` time and date settings
timedatectl set-ntp true
arch-chroot `/mnt`
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
more /etc/adjtime # Verify that the hardware clock is set to UTC
exit
```

Next we install dependencies that may be useful later.

```bash
# root@archiso
arch-chroot `/mnt`
pacman -Syu
pacman -S vim networkmanager
# Ensure default editor is vim. See https://wiki.archlinux.org/title/Environment_variables
echo 'EDITOR=vim' >> /etc/environment
# You need internet to install packages, including this package. So you must install networkmanager here
systemctl enable NetworkManager.service
# See https://wiki.archlinux.org/title/Microcode#Installation. This needs to be done before grub-mkconfig is run which adds the microcode files as `initrd` to GRUB later.
pacman -S amd-ucode
exit
```

Later in the Windows partition, we have to make sure it [plays well with the existing Windows partition](https://wiki.archlinux.org/title/System_time#UTC_in_Microsoft_Windows)

Then we make sure that the locales are generated properly:

```bash
# root@archiso
arch-chroot `/mnt`
vim /etc/locale.gen
# Comment out en_US.UTF-8, UTF-8 and other required locales
locale-gen
# You can set your own default locale here
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
exit
```

Add the hostname, which would be the name of the computer on a network.

If you are having trouble naming the computer, a good suggestion will be to avoid having an owner's name as part of the hostname. For example, Sam has a PC with a cute teal case they use for gaming. She could use a hostname like `teal-gaming-pc`, not `sams-pc`, so the user is added before the hostname like `sam@teal-gaming-pc` instead of `sam@sams-pc`.

```bash
# root@archiso
arch-chroot `/mnt`
echo 'your-computer-name' >> /etc/hostname
exit
```

Next, we create a non root administrative user. Using the previous example, Sam has been using `root@teal-gaming-pc`, so they will now create a user account `sam@teal-gaming-pc` for normal use.

```bash
# root@archiso
arch-chroot `/mnt`
useradd -m {you} # Creates a "/home/you" account. You can replace you with whatever else.
passwd {you}

# Give yourself sudo privileges
pacman -S sudo
# The sudo group is "wheel"
# To add your user to the existing "wheel" group
usermod -aG wheel {you}

visudo
# Under the line "Uncomment to allow members of the group wheel to execute any command...
# ---
# # Uncomment the line (the percentage is crucial to distinguish between a user and a group)
# %wheel ALL=(ALL:ALL) ALL
# ---

su - you # Use you
exit # you@archiso on /mnt -> root@archiso on /mnt
exit # root@archiso on /mnt -> root@archiso on /
```

Install `yay`, which will allow you to install AUR packages maintained by the community. Once `yay` is installed, you will not be able to uninstall `yay`.

```bash
# root@archiso
arch-chroot /mnt
pacman -S --needed git base-devel
su - you
# Doesn't matter where this is installed, `~` is fine
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
exit
exit
```

See https://github.com/Jguer/yay#source.

Run `mkinitcpio` manually to check if there are any missing firmware. This is actually run when installing linux via pacstrap for the first time. Note the possible missing firmware, and you may [install the packages listed on the wiki](https://wiki.archlinux.org/title/Mkinitcpio#Possibly_missing_firmware_for_module_XXXX).

```bash
# root@archiso
arch-chroot /mnt
mkinitcpio -P
# Note missing packages, e.g. bfa, qed, qla2xxx
pacman -S linux-firmware-qlogic
# root@archiso
su - you
# Note AUR packages, e.g. xhci_pci, wd719x, aic94xx, ast
# You can use the AUR meta package `mkinitcpio-firmware`, but it will install firmware packages not
# raised in the mkinitcpio warnings, which is likely to be unnecessary.
yay -S upd72020x-fw wd719x-firmware aic94xx-firmware ast-firmware
exit
# root@archiso
# Now we ensure consolefont will not complain about not being able
# to set the font at boot by adding the bottom 2 lines
echo "FONT=lat2-16" >> /etc/vconsole.conf
echo "FONT_MAP=8859-2" >> /etc/vconsole.conf 
su - you
# you@archiso
exit # you@archiso on /mnt -> root@archiso on /mnt
mkinitcpio -P
exit # root@archiso on /mnt -> root@archiso on /
```

Set the root password.

```bash
# root@archiso
arch-chroot /mnt
passwd
exit
```

## Setting up the GRUB bootloader

Finally, we install the boot loader. We use GRUB as it is the most robust boot loader option, e.g. supporting both UEFI and BIOS.

See [Using GRUB for Arch (UEFI)](./using-grub-for-arch.md#uefi--gpt-windows-dual-boot) for more information.

## Setting up KDE Plasma

Install the `xorg` desktop environment. Optionally we can use wayland later, but it is known to be extremely glitchy on KDE running Arch.

```bash
# root@new-arch-partition
# This installs xorg related dependencies and xorg-server
# Choose man-db (default)
pacman -S xorg
# As of 20 June 2025, wayland session will only be installed by default. Since kwin has been split
# into kwin-wayland and kwin-x11, users need to install plasma-x11-session manually
pacman -S plasma-x11-session

# Print the graphics card
lspci -k | grep -A 2 -E "(VGA|3D)"
# Check https://www.nvidia.com/en-us/drivers/unix/legacy-gpu/ if the card is listed.
```

We don't bother with Wayland for now until [it works with SDDM](https://wiki.archlinux.org/title/Wayland#Display_managers).

<hr />

<details>
<summary>Installing community NVIDIA drivers (Works well but 3D games have considerable frame drops on Steam)</summary>
<br />
This provides the DRI driver for 3D acceleration, and provides the DDX driver 2D acceleration in Xorg.

```bash
pacman -S mesa lib32-mesa xf86-video-nouveau
```

https://wiki.archlinux.org/title/Nouveau#Installation

</details>
<br />
<details>
<summary>Installing official NVIDIA drivers (Currently freezes on boot)</summary><br />

```bash
# root@new-arch-partition
# Check https://www.nvidia.com/en-us/drivers/unix/legacy-gpu/ if the card is listed. If not, proceed
# with using nvidia proprietary

# Enable multilib for pacman. See https://wiki.archlinux.org/title/official_repositories#Enabling_multilib
vim /etc/pacman.conf
# -----
## Uncomment both lines! The [multilib] line and the Include line
# [multilib]
# Include = /etc/pacman.d/mirrorlist
# ------
pacman -Syu # multilib should be now listed as a package database.

```

Depending on your GPU make, if your Nvidia GPU is one of the later models (e.g. RTX 5090), you might need to use a different driver (i.e. `nvidia-open` instead of `nvidia`). Refer to:
- [Nvidia Arch Linux wiki article](https://wiki.archlinux.org/title/NVIDIA)
- [List of GPUs supported by `nvidia-open` package](https://github.com/NVIDIA/open-gpu-kernel-modules)

```bash
# nvidia for older GPUs, e.g. RTX 3070
pacman -S nvidia-open
pacman -S nvidia-utils
# We need to run mkinitcpio -P after nvidia updates so we put this in a pacman hook
mkdir /etc/pacman.d/hooks
vim /etc/pacman.d/hooks/nvidia.hook
```

```conf
# /etc/pacman.d/hooks/nvidia.hook
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
# Change to nvidia-open depending on the module installed
Target=nvidia
Target=linux
# Change the linux part above and in the Exec line if a different kernel is used

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
## Unnecessary
# NeedsTargets
Exec=/usr/bin/mkinitcpio -P
## If you want it to run only once and not multiple times
# Exec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
```

Also [enable an early KMS start](https://wiki.archlinux.org/title/Kernel_mode_setting#Early_KMS_start) to prevent issues.

```bash
vim /etc/mkinitcpio.conf
##
# MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
## You can add shutdown to end of HOOKS=(... shutdown) to prevent long shutdown
# HOOKS=(... shutdown)
#
```

You might also want to specify both `COMPRESSION` (to suppress `"COMPRESSION_OPTIONS is set without also setting COMPRESSION. Configure COMPRESSION explicitly"` warning) and `COMPRESSION_OPTIONS` as you may face problems generating the `initcpio` image `sudo mkinitcpio -P`
successfully in the future.

```bash
vim /etc/mkinitcpio.conf
##  
# See https://wiki.archlinux.org/title/Mkinitcpio#COMPRESSION for other supported algorithms
# COMPRESSION=zstd
# COMPRESSION_OPTIONS=(-v -5 --long)
#
```

</details>
<hr />

```bash
pacman -S plasma-meta
```

For providers for every dependency choice in `plasma-meta`:

- Choose `qt6-multimedia-ffmpeg` over `qt6-multimedia-gstreamer`. The `ffmpeg` variant [is default](https://doc.qt.io/qt-6/qtmultimedia-index.html#the-ffmpeg-backend) while the `gstreamer` backend is only available on Linux and only recommended for **embedded applications**. See [Qt Multimedia Native Backends](https://doc.qt.io/qt-6/qtmultimedia-index.html#native-backends) documentation here
- Choose `jack2` over `pipewire-jack` due to superior feature offerings. See https://wiki.archlinux.org/title/JACK_Audio_Connection_Kit#Comparison_of_JACK_implementations
- Choose `noto-fonts`. Really just personal preference.
- Choose `phonon-qt6-vlc` if you require more supported features like streaming and transcoding (or if you like VLC player in general) while `phonon-qt6-mpv` focuses on core playback functionality and customisation and is considered more lightweight and performant option derived from MPV
- Choose `wireplumber`. Even [`pipewire-media-session` devs recommend it](https://gitlab.freedesktop.org/pipewire/media-session#pipewire-media-session).
- Choose `phonon-qt5-gstreamer`. See [the wiki](https://wiki.archlinux.org/title/KDE#Which_backend_should_I_choose?) and the [feature set comparison here](https://community.kde.org/Phonon/FeatureMatrix). Since I don't have or intend to get BluRay, `phonon-qt5-gstreamer` is the obvious choice for me.

Install KDE applications. There really is no need to install `kde-applications-meta`, just install the ones you need and add more later. Or just install the individual applications you remember.

```bash
pacman -S kde-accessibility-meta kde-graphics-meta kde-multimedia-meta kde-sdk-meta kde-system-meta kde-utilities-meta
```

For providers:

- Choose `fcron`. See the differences here: https://wiki.archlinux.org/title/cron#Cronie vs https://wiki.archlinux.org/title/cron#Fcron
- `tesseract-data-eng`, the English package. I think this is used in OCR in one of the KDE applications.

Now let's install `sddm` since we are using KDE.

```bash
pacman -S sddm
# To enable graphical login, enable the appropriate systemd service. For example, for SDDM, enable sddm.service.
systemctl enable sddm
```

## Setting up the KDE user preferences and applications

### Time
Set time to 24 hours, showing seconds.

### Double click to open files and folders on Dolphin

Workspace behavior -> General behavior -> Clicking files or folders -> Selects them

### Terminal: Disabling bracketed paste in your terminal (e.g. KDE's Konsole)

Bracketed paste seems to be switched on by default for Konsole, the default KDE terminal app.

```sh
# Ctrl+C

some-package-name

# Ctrl+V (with control characters)

sudo pacman -S ^[[200~some-package-name~

```

Add the following line to your shell profile to disable this:

```sh
printf "\e[?2004l"
```

**Read more about bracketed paste in terminals**
- https://cirw.in/blog/bracketed-paste: Author of this feature explains why it is a good thing to have this enabled so you wouldn't accidentally 
- http://www.xfree86.org/current/ctlseqs.html#Bracketed%20Paste%20Mode

### Applications

Install a firewall

```bash
sudo pacman -S ufw
```

Install Firefox and Firefox Developer Edition.

```bash
sudo pacman -S firefox firefox-developer-edition
```

### Steam


```bash
pacman -S steam
# For the lib32-vulkan-driver, choose the variant with the same brand as your GPU (e.g. lib32-nvidia-utils)
```

<hr />

<details>
<summary>If you have installed nouveau</summary>
<br />
Choose the last packages (Do not install `nvidia-utils` and `lib32-nvidia-utils` unless you managed to blacklist them properly via Xorg). Otherwise you will face a problem booting into SDDM when `nouveau` was blacklisted by `nvidia-utils` and you require to boot into SDDM manually via `modprobe nouveau`.
</details>

### Twitter like SVG fonts

Install the AUR package `ttf-twemoji` instead of `ttf-twemoji-color`, as SVG font emojis will only output mono coloured emojis.

### No memory error when running `sudo mkinitcpio -P`

```shell
zstd: error 70 : Write error : cannot write block : No space left on device 
bsdtar: Write error
bsdtar: Write error
==> ERROR: Image generation FAILED: 'bsdtar (step 1) reported an error'
```

You might want to attempt to add compression options to `/etc/mkinitcpio` options file to allow image generation after package update to proceed successfully.

```conf
COMPRESSION_OPTIONS=(-v -5 --long)
```

### Missing packages while running `sudo mkinitcpio -P`

You might encounter missing firmware packages, e.g.

```shell
==> Starting build: '6.9.7-arch1-1'
  -> Running build hook: [base]
  -> Running build hook: [udev]
  -> Running build hook: [modconf]
  -> Running build hook: [kms]
==> WARNING: Possibly missing firmware for module: 'ast'
  -> Running build hook: [keyboard]
```

| Module | Package |
| -- | -- |
| `aic94xx` | `aic94xx-firmware` (AUR) |
| `ast` | `ast-firmware` (AUR) |
| `bfa` | `linux-firmware-qlogic` |
| `bnx2x` | `linux-firmware-bnx2x` |
| `liquidio` | `linux-firmware-liquidio` |
| `mlxsw_spectrum` | `linux-firmware-mellanox` |
| `nfp` | `linux-firmware-nfp` |
| `qed` | `linux-firmware-qlogic` |
| `qla1280` | `linux-firmware-qlogic` |
| `qla2xxx` | `linux-firmware-qlogic` |
| `wd719x` | `wd719x-firmware` (AUR) |
| `xhci_pci` | `upd72020x-fw` (AUR) |

See [5.4 Possibly missing firmware for module XXXX in the mkinitcpio docs](https://wiki.archlinux.org/title/Mkinitcpio) for an updated list of packages

## References

- [Installation Guide](https://wiki.archlinux.org/title/installation_guide)
- [KDE Plasma on the Arch wiki](https://wiki.archlinux.org/title/KDE#Plasma)
