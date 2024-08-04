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
| Select pool of ip addresses given out by DHCP server | Set "Addresses to Give Out" to `192.168.{custom_octet}.2-192.168.{custom_octet}.254`. We leave out `192.168.{custom_octet}.1` for the gateway. |
| Select DNS servers | Set "DNS Servers" to `192.168.1.1` |
| Select lease time | Set "Lease time" to `00:30:00` |

Once done, this should automatically:

- create a new row in IP > DHCP Server > DHCP (i.e. `{mikrotik-device-ip}/webfig/#IP:DHCP_Server`) named `dhcp1`. Since we will not use this DHCP, we will disable this row
- create a new row in IP > DHCP Server > Networks (i.e. `{mikrotik-device-ip}/webfig/#IP:DHCP_Server.DHCP`) with address, gateway and DNS servers above the default `defconf` row. **Notice the "DNS Servers" value for that row is empty at this point.** Click on the row and set the DNS server as `192.168.{custom_octet}.1`. This is important to prevent a "failed" status connecting to the default IP range that can be seen as a row from IP > ARP, and also important to prevent 2 IPs from showing in your client machine ethernet connection (e.g. DNS Servers: `192.168.88.1`, `192.168.{custom_octet}.1`)
- create a new row in IP > Pool > Pools (i.e. `{mikrotik-device-ip}/webfig/#IP:Pool.Pools`) named `dhcp_pool1` with the addresses

It's recommended that you [set up custom gateway IPv4](./change-gateway-ipv4.md) first and use the newly created gateway IP to interface with RouterOS WebFig.

Return to IP > DHCP Server > DHCP (i.e. `{mikrotik-device-ip}/webfig/#IP:DHCP_Server`) and click on `defconf`.

Update "Address Pool" from `default-dhcp` to the generated `dhcp_pool1` option.

On your client machine, renew the DHCP lease and there should be an IP assigned within the `dhcp_pool1` range now.

## Uncertainties

- Must the relay in the DHCP server be always set for non `defcon` rows? It seems like only 1 row without a relay can be set (from the `defconf` row). This results in having to resort to change the IP pool option of `defconf` row in the DHCP list.

## References:

- [RouterOS current docs: DHCP](https://help.mikrotik.com/docs/display/ROS/DHCP#DHCP-Setup)
- [RouterOS old docs: DHCP](https://wiki.mikrotik.com/wiki/Manual:IP/DHCP_Server)
- [Subnet calculator](https://www.subnet-calculator.com/subnet.php?net_class=B)
