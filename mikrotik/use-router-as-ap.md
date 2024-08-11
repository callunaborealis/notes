# Use router as an access point

Disable DHCP server in your router-as-access-point
Ensure ethernet plug transmitting or receiving from the DHCP server is either:
- set as LAN and not WAN manually in RouterOS, or
- if there are multiple ethernet ports on the router-as-access-point, move the ethernet connection from the DHCP server from the WAN (or Internet) to LAN port (usually numbered)  