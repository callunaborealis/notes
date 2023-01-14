# Using universal time

## Windows

- Open regedit then browse to `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation`
- Create a new QWORD value (for 64-bit Windows), or DWORD value (for 32-bit Windows), variable called `RealTimeIsUniversal` and modify its hexadecimal value to 1.
- Reboot the system to see the clock in UTC time. Sync with the time servers in Settings again.

## References

- Reference for setting Windows default time: https://wiki.gentoo.org/wiki/System_time#Dual_booting_with_Windows