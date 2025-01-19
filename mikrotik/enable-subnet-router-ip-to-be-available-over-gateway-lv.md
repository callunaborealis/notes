# Enable subnet device RouterOS to be available over gateway network

## Solution: Subnet device firewall

**Tested with:** [MikroTik hAP ac²](https://mikrotik.com/product/hap_ac2) running RouterOS v6.49.15 stable

Under "IP" left tab, select "Services" sub left tab (e.g. `{mikrotik-device-ip}/webfig/#IP.Services`).

Take note of the ports for HTTP (e.g. `80`) and winbox (e.g. `8291`). Ensure both ports are not disabled.

Under "IP" left tab, select "Firewall" sub left tab (e.g. `{mikrotik-device-ip}/webfig/#IP.Firewall`).

Add 2 new rules:

- Chain: `input`
- Protocol: `6 (tcp)`
- Port: 1 for HTTP (e.g. `80`), winbox (e.g. `8291` by default). This requires creating 2 separate rules.
- Action: `accept` (on by default)

Position these 2 new rules **above** any broader rule that drops all connections not coming from LAN. A broad rule seems to be always created by default, e.g. `defconf: drop all not coming from LAN`

### Intermediate unmanaged switches will affect connections!

Remember to either **directly connect** the subnet connection to a physical interface of the Mikrotik device. Ensure that there are no intermediate devices (especially unmanaged switches).

It is likely that since unmanaged switches are a black box, they might seem like they are forwarding the same IP addresses correctly but have internally assigned a new IP address via a DHCP server instead, for either security, or to incentivise network users to buy their replacement managed switches instead.