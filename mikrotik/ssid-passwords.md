# Wi-Fi Passwords

**Tested with:** [MikroTik hAP ac²](https://mikrotik.com/product/hap_ac2) running RouterOS v6.49.15 stable
**Tested with:** [MikroTik Chateau PRO ax](https://mikrotik.com/product/chateau_pro_ax) running RouterOS v7.15.2

Under "Wireless" left side tab, select the "Security Profiles" top tab (e.g. `#Wireless.Security_Profiles`).

New security profiles created should by default be a **minimum of WPA2 using AES encryption** to be secure. Unless your network is supporting really old devices that can only use WPA. Avoid TKIP as it is insecure and slows down your network device.

## References

- [Router OS Wiki: Wireless > Wi-Fi](https://help.mikrotik.com/docs/display/ROS/WiFi)
- [Microsoft Support: Faster and more secure Wi-Fi in Windows](https://support.microsoft.com/en-us/windows/faster-and-more-secure-wi-fi-in-windows-26177a28-38ed-1a8e-7eca-66f24dc63f09)
- [Apple: Recommended settings for Wi-Fi routers and access points](https://support.apple.com/en-us/102766)
- [How To Geek: Wi-Fi Security: Should You Use WPA2-AES, WPA2-TKIP, or Both?](https://www.howtogeek.com/204697/wi-fi-security-should-you-use-wpa2-aes-wpa2-tkip-or-both/#wpa2-vs-wep-wpa-and-wpa3)
