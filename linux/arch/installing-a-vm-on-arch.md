# Installing a VM on Arch Linux

## Qemu to Windows on Arch

```sh
sudo pacman -S qemu-full # Perhaps minimum qemu would work? Not sure though
sudo pacman -S libvirt # Required to connect qemu with virt-manager
sudo pacman -S virt-manager # Client to show VMs
sudo systemctl start libvirtd.service
sudo systemctl status libvirtd.service
```
At this point, check the systemctl logs below for missing `dnsmasq` package. This is required for starting the "default" network via virt-manager.
The Arch Wiki article for `libvirtd` also recommends installing `iptables-nft` but it isn't required for `libvirtd.service` as far as I checked.

If you see `/dev/kvm` not found, check if virtualisation is enabled for your PC. This requires going into BIOS mode and enabling virtualisation
(e.g. `vmx` / `svm`) is enabled.

If so, install `dnsmasq`:

```sh
sudo pacman -S dnsmasq
```

From here, download a copy of the [Windows 11 ISO](https://www.google.com/search?client=firefox-b-d&q=windows+11+iso)

Optionally, create a folder via vert-manager GUI in `/var/lib/libvirt/images/pool`

```sh
sudo mv Win11_23H2_EnglishInternational_x64v2.iso /var/lib/libvirt/images/pool
```

On `virt-manager`, create a new VM. Ensure Windows 11 [can run on the VM specs](aka.ms/WindowsSysReq)

“This PC can’t run Windows 11” warning will show due to [TPM](https://learn.microsoft.com/en-us/windows/security/hardware-security/tpm/trusted-platform-module-overview)

Press and hold `Shift` + `F10` (+ `Fn` might be necessary) to open `cmd.exe`. In `cmd.exe`, we should disable TPM checking in the Windows 11 installer:

```bat
@REM We could find the command manually through the regedit GUI...
regedit
@REM Go to HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig
@REM Create 3 new values, i.e. New > DWORD (32-bit) value
@REM Create BypassTPMCheck to 1
@REM Create BypassRAMCheck to 1
@REM Create BypassSecureBootCheck to 1

@REM Or...
REG ADD HKLM\SYSTEM\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1
REG ADD HKLM\SYSTEM\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1
REG ADD HKLM\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1
```

Next we have to ensure that the videos are shown in the correct resolution. Unfortunately I have yet to come with a solution for this.

## Sources

- [How to check if virtualisation is enabled](https://wiki.archlinux.org/title/KVM#Hardware_support)