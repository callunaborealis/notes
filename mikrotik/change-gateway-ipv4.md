# Set up custom DHCP IPv4 range

Tested with: [MikroTik RB5009UPr+S+IN](https://mikrotik.com/product/rb5009upr_s_in) running RouterOS 7.15.3 (stable)

## Pre-requisites

Ensure [the custom IP is within range if a custom pool of IPs is used for the IPv4 DHCP server settings](./set-up-custom-dhcp-ipv4-range.md) and note the custom octet used in the IPv4 range (e.g. `192.168.88.1` where `88` is the custom octet)

## Steps

Under IP > Addresses (i.e. `{mikrotik-device-ip}/webfig/#IP:Addresses`), click on "Add New".

| --- | --- |
| Address | `192.168.1.1/24` |
| Network | `192.168.1.0` |

## Uncertainties

- It seems there can be multiple addresses for the bridge interface, e.g. both `192.168.88.1` and `192.168.1.1` can both be set up to access the network. 
- Disabling the default gateway IP so that only the custom default gateway IP is used