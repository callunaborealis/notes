# Setting up Arch Linux on an old MacBook Pro 13"

## Pre-requisites

- [Download and set up an Arch installation media on an external drive](./create-installation-media.md).
- [Set up partitions](./initialising-partitions.md)

## Booting up the live environment

- Download [rEFInd](https://sourceforge.net/projects/refind/). Unzip it into a spare removable drive.
- CTRL+R to load up the Recovery Partition
- Open Terminal

```sh
csrutil disable
# Restart your computer FIRST before proceeding. Then reload the Recovery Partition terminal and return here
cd /Volumes/your_spare_removable_drive/refind-XXX
./refind-install
csrutil enable
```
- Now you can restart the conputer
- When you start your MacBook Pro for the first time, you'll load rEFInd on power on. **However, the option to load the Recovery Partition directly does not seem to work** as it always return a "no entry symbol" when selected. The only way to select the Recovery Partition is to hold CTRL+R on power on.

See https://www.ianmaddaus.com/post/refind/#automaticEnableSIP

- Use Disk Utility to clear out the partition. Just one big empty space after the macOS related partitions. We will be changing this again later.

- Start up EFI Boot on the removable drive
- Set the timezone, time etc
- Follow https://wiki.archlinux.org/title/mac#Option_1:_EFI to use `cgdisk /dev/sda` (Not `/dev/sdaXX`) to format the already created partitions. Buffer the first partition adjacent to the OSX partition by 128MB (by having first sector as +128M) (due to [Apple's partition policy](https://developer.apple.com/library/archive/technotes/tn2166/_index.html#//apple_ref/doc/uid/DTS10003927-CH1-SUBSECTION5)). See https://wiki.archlinux.org/title/mac#Option_1:_EFI
 - 128.0MB Free Space, 20.0 GiB Linux x86-64 root (/) "root" and 235.9 GiB Linux x86-64 /usr "home"
 - Proceed with formatting the swap via mkswap and root/home ext4 drives as per normal
 - swapon for the swap partition, mount root onto /mnt
 - `pacstrap /mnt base linux linux-firmware`
 - `arch-chroot /mnt` to enter your newly create Arch partition for the first time
 - `vim /etc/locale.gen` and uncomment all the language codes required. THEN run `locale-gen`. As not doing so will at least result in a perl-related locale warning when installing `vim`. If you deleted / modified `locale.gen` by mistake, deleting the corrupted `locale.gen` and reinstalling `glibc` will restore the file.
 - Install other essential packages, like `vim`, `git`, `networkmanager`, `iw`, `iwd`, `wpa_supplicant`, `dhcp` (for dynamic IP address unless you want to assign a static IP in the network yourself)
- Reboot the system and re-enter the portable EFI Boot when done
- Set up the Boot Loader as recommended for Macs: https://wiki.archlinux.org/title/mac#Using_the_native_Apple_boot_loader_with_systemd-boot_(Recommended). I started with an easier approach first
 - If this does not work, reinstall refind, which worked in my case.
- Create a new user as root

```bash
useradd -m you # Creates a "/home/you" account. You can replace you with whatever else.
passwd you
logout # Once password is confirmed

# Log in as your new home/you account
```

> The account is locked due to 3 failed logins? Use `faillock --user you` to see the length of the lockout, then `faillock --user you --reset` to reset it.

- Connect to the network. This is assuming you installed all the necessary network packages before switching to the actual Arch partition.
 - `ip link` to list all the network interfaces
 - `ip link set <interface> up` to activate the network interface (could be en / wlan)
 - `iw dev <wlan_interface> scan | grep "SSD"` to see all the wireless LAN access points available near your machine
 - `lscpi -vnn -d 14e4` to detect Broadcom controllers. I had  the BCM4331, so I installed `broadcom-wl` via AUR (although b43-firmware is also ok)
 - 

- Add your user account `you` as a superuser group "sudo" so  that yay can be built and installed next.
 
 ```bash
 # As root...
 pacman -S sudo
 
 usermod -aG wheel you # Add your user to the existing "wheel" group
 
 # Alternatively if you prefer "sudo"
 groupadd sudo # Adds the sudo group. You can forgo this step to use the existing wheel group
 usermod -aG sudo you
 
 # Opens the sudo configuration
 EDITOR=vim visudo
 
 # Under the line "Uncomment to allow members of the group wheel to execute any command...
 # Uncomment the line (the percentage is crucial to distinguish between a user and a group)
 %wheel ALL=(ALL:ALL) ALL
 # Or if you chose sudo earlier...
 %sudo  ALL=(ALL:ALL) ALL
 
 ```
- Reboot and login again as your new user account before proceeding.

- Now install `yay` as your `you` account. You might need to do a `sudo pacman -S --nneeded base-devel` before proceeding, especially if an error regarding missing packages is thrown when doing a `makepkg -si` inside `yay-git`

```bash
git clone https://aur.archlinux.org/yay-git.git
sudo pacman -S --nneeded base-devel # Optional if you face problems with the next step
makepkg -si

# Just for reference, no need to install this package
yay -Syu # Update
yay -S gparted # Install a package
yay -Rns gparted # Remove a package
```

See https://low-orbit.net/arch-linux-how-to-install-yay

- I also decided to go with [Budgie](https://wiki.archlinux.org/title/Budgie) as it is reportedly Gnome 2, but lightweight and productive.

> Budgie is for Linux users who like the Gnome desktop look but can do without the bloat. It actually looks simpler than Gnome as it’s designed to help the users focus more on work. The main Budgie menu is both mouse and keyboard friendly. The system is easily configured using its all-in-one center called Raven. Budgie is simple and attractive and also lightweight as most of those in this list of best desktop environments for Arch. So, if you have an old system you want to revive and get work done, Budgie would be a nice desktop environment for Arch or any other distro that supports it.

 - Packages: `pacman -S budgie-desktop gnome gnome-extra gdm gnome-control-center gnome-terminal`. `gnome-terminal` is extremely important as there is no way without an external boot drive to install it without a terminal
 - `systemctl enable gdm.service`: This will enable GDM on arch boot with the Budgie Desktop environment 
- Other useful packages for Budgie
 - Everything in the Mac section for the keyboard lights
 - `libinput-gestures`: https://github.com/bulletmark/libinput-gestures
  
## References

- https://gist.github.com/gretzky/149e8ebe7a8f317cc687f82c1aacf1a0
  - Another useful Macbook Pro + Arch guide
- https://wiki.archlinux.org/title/mac
  - Using this guide at the moment
- https://www.youtube.com/watch?v=C5G9tr1JS_Y
  - Holding alt did not make the Arch boot drive visible. But this guy has an alternative
- https://nickolaskraus.io/articles/installing-arch-linux-on-a-macbookpro-part-1/
  - Interesting but did not refer to this guide