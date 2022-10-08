# Setting up i3 on an old laptop which could not handle Gnome or KDE

- Use `ls /sys/firmware` to check if it will support EFI (which it didn't in my case).
You can also use `parted -l`. Check under "Partition Table". If it shows "msdos", it is using MBR. If it shows "gpt", then it will work with UEFI.
- You can use `sgdisk -g /dev/sda` to convert the partition table into GPT from MBR. See https://wiki.archlinux.org/title/GPT_fdisk#Convert_between_MBR_and_GPT
- I created 2M BIOS (as it is a MBR -> GPT convert), 300M EFI System Partition, 5 GB Swap (As the RAM stated it was 10GB). To ensure it plays nicely with `systemd-boot` (reportedly, never experienced this first hand), mount it under `/boot`

```bash
mount /dev/sda4 /mnt
swapon /dev/sda3
mount --mkdir /dev/sda2 /mnt/boot
```

- I installed GRUB due to its flexibility and familiarity
- Next, installed the [i3](https://wiki.archlinux.org/title/I3) desktop environment, which claims to be light and performant, which appealed to the 12 year old netbook, which did not fare well even under Gnome.
  - Install `i3-wm` 
  - Add "exec i3" into a new file `~/.xinitrc`
  - Run `startx` to run and start i3-wm


## More options

### Maintain user i3 configuration

- `cp /etc/i3/config ~/.config/i3/config`: Copy sample i3 Config to home directory for your current user. Warning! This overrides the settings set by the i3 Wizard
- Replace all Mod1 values to $mod in `~/.config/i3/config`:

```config
set $mod Mod4 # or Mod1
```
- Using vim substitution (i.e. `:%s/Mod1/$mod/` => `[n]` (Will find the next one) => `[.]` Confirm change for highlighted one )

Using `ttf-fira-code` to replace the default font
- `sudo pacman -S ttf-fira-code ttf-fira-mono`
- `sudo vim ~/.config/i3/config`
- `font pango:Fira Code Medium 9`
- $mod+Shift+R to reload i3-wm and see the changes made to the i3 DE

### Install `rofi` to replace `dmenu_run`

### Replacing XTerm default font

- `fc-list | grep "Mono"` - List all installed fonts
- `xterm -fa "IBM Plex Mono SmBld" -fs 9` - To preview how the shell emulator will look like
- `sudo vim ~/.Xresources`

```conf
xterm*faceName: Fira Mono Medium
xterm*faceSize: 9
```
 
- `xrdb -merge ~/.Xresources`

## References

- https://ostechnix.com/install-budgie-desktop-environment-arch-linux/
  - A useful guide 