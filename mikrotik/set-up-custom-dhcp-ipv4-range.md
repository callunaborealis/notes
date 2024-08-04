# Set up custom DHCP IPv4 range

Tested with: [MikroTik RB5009UPr+S+IN](https://mikrotik.com/product/rb5009upr_s_in) running RouterOS 7.15.3 (stable)

In essence, changing how you access the router admin from the default IP (i.e. 192.168.88.1) to a custom IP (e.g. 192.168.1.0), which is essential to avoid if you are setting up multiple MikroTik devices on the same network which has the same default IP.

Click on the IP left tab and DHCP top tab (i.e. `{mikrotik-device-ip}/webfig/#IP:DHCP_Server.DHCP`), click on **DHCP Setup** (i.e. `{mikrotik-device-ip}/webfig/#IP:DHCP_Server.DHCP_Setup`)

By default you should have `192.168.88.10 - 192.168.88.254`. We will now attempt to create a new range with a custom 3rd octet:

| Step | Option |
| --- | --- |
| Select interface to run DHCP server on | `bridge` |
| Select network for DHCP Addresses | `192.168.{custom_octet}.0/24` |
| Select gateway for given network | `192.168.{custom_octet}.1` |
| If this is remote network,enter address of DHCP relay | You should see a "There is no such IP network on selected interface" message on top by default. Set it as `192.168.{custom_octet}.1` |
| Select pool of ip addresses given out by DHCP server | Set "Addresses to Give Out" to `192.168.1.2-192.168.1.254` |
| Select DNS servers | Set "DNS Servers" to `192.168.1.1` |
| Select lease time | Set "Lease time" to `00:30:00` |

Once done, this should automatically:

- create a new row in IP > DHCP Server > DHCP (i.e. `{mikrotik-device-ip}/webfig/#IP:DHCP_Server`) named `dhcp1`
- create a new row in IP > DHCP Server > Networks (i.e. `{mikrotik-device-ip}/webfig/#IP:DHCP_Server.DHCP`) with address, gateway and DNS servers above the default `defconf` row
- create a new row in IP > Pool > Pools (i.e. `{mikrotik-device-ip}/webfig/#IP:Pool.Pools`) named `dhcp_pool1` with the addresses

## Next steps

- [Set up custom gateway IPv4](./change-gateway-ipv4.md)

## Uncertainties

- Must the relay in the DHCP server be always set?

## References:

- [RouterOS current docs: DHCP](https://help.mikrotik.com/docs/display/ROS/DHCP#DHCP-Setup)
- [RouterOS old docs: DHCP](https://wiki.mikrotik.com/wiki/Manual:IP/DHCP_Server)
- [Subnet calculator](https://www.subnet-calculator.com/subnet.php?net_class=B)