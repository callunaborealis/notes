# Change gateway IPv4

Tested with: [MikroTik RB5009UPr+S+IN](https://mikrotik.com/product/rb5009upr_s_in) running RouterOS 7.15.3 (stable)

## Pre-requisites

Ensure [the custom IP is within range if a custom pool of IPs is used for the IPv4 DHCP server settings](./set-up-custom-dhcp-ipv4-range.md) and note the custom octet used in the IPv4 range (e.g. `192.168.88.1` where `88` is the default third octet, and `192.168.1.1` where `1` is the custom third octet)

## Steps

Under IP > Addresses (i.e. `{mikrotik-device-ip}/webfig/#IP:Addresses`), click on "Add New".

| Label | Value |
| --- | --- |
| Address | `192.168.1.1/24` |
| Network | `192.168.1.0` |
| DNS Servers | `192.168.1.1` |

Under IP > DHCP Server > Networks (i.e. `{mikrotik-device-ip}/webfig/#IP:DHCP_Server.Networks`), confirm that there is a row corresponding to the address, gateway IPv4, which should be available by default for the default `88` octet. If not, it is likely due to [any previously created custom pool of IPs assigned to a DHCP server](./set-up-custom-dhcp-ipv4-range.md). Not having this network row will result in a self-assigned non local IPs of connected devices and a loss of Internet connection, forcing the user to perform a hard reset.

## Uncertainties

- It seems there can be multiple addresses for the bridge interface, e.g. both `192.168.88.1` and `192.168.1.1` can both be set up to access the network.
- How to disable the default gateway IP so that only the custom default gateway IP is used. This can be done by deleting / disabling both the DHCP and Server row (1 at a time) only in the gateway router