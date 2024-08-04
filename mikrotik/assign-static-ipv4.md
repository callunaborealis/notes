# Assigning static IPv4 for client

Tested with: [MikroTik RB5009UPr+S+IN](https://mikrotik.com/product/rb5009upr_s_in) running RouterOS 7.15.3 (stable)

Connect your client to your router.

Under IP > DHCP Server > Leases (i.e. `{mikrotik-device-ip}/webfig/#IP:DHCP_Server.Leases`), find the connected client using a dynamically assigned IP. Click on the row. Click on "Make Static" button. Change the IP Address.