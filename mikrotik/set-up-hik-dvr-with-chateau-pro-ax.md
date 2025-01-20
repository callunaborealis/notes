# Set up HiK DVRs with Chateau Pro AX

This requires ports to be forwarded:
- DVR static IP, e.g. `192.168.1.3`
- Required ports:
  - `8000` - HiK-Connect default "Device Port" (tcp)
  - `554` - HiK default RTSP port (tcp/udp), and
  - `80`/`443` - http(s) (tcp).
  
See [HiK Vision technical article on default network ports used](https://www.hikvision.com/content/dam/hikvision/ca/bulletin/technical-bulletin/technical-article/tb_network_port_list.pdf). A [local copy](./set-up-hik-dvr-with-chateau-pro-ax--hik-ports.pdf) is saved here too.

## WebFig

Under "IP" left tab, select "Firewall" sub left tab (e.g. `{mikrotik-device-ip}/webfig/#IP.Firewall.NAT`) then "NAT" in the top tab.

Add 2 new NAT rules:

Expand the General Tab:
- Chain: `dstnat`
- Protocol: `tcp` (or `udp` for `udp` ports).
- Dst. Port: Enter the port number (e.g. `8000`).

Expand the Action Tab:
- Action: `dst-nat`
- To Address: Enter the static IP of the DVR.
- To Ports: Same as the Dst. Port.

## Terminal

```sh
# Forward port 8000 (tcp)
/ip firewall nat add chain=dstnat protocol=tcp dst-port=8000 action=dst-nat to-addresses=192.168.1.3 to-ports=8000 comment="Forward HiK DVR Service Port"
```

```sh
# Forward port 554/10554 (tcp/udp)
/ip firewall nat add chain=dstnat protocol=tcp dst-port=554 action=dst-nat to-addresses=192.168.1.3 to-ports=554 comment="Forward HiK DVR RTSP Server Listen TCP port 1"
/ip firewall nat add chain=dstnat protocol=udp dst-port=554 action=dst-nat to-addresses=192.168.1.3 to-ports=554 comment="Forward HiK DVR RTSP Server Listen UDP port 1"
/ip firewall nat add chain=dstnat protocol=tcp dst-port=10554 action=dst-nat to-addresses=192.168.1.3 to-ports=10554 comment="Forward HiK DVR RTSP Server Listen TCP port 2"
/ip firewall nat add chain=dstnat protocol=udp dst-port=10554 action=dst-nat to-addresses=192.168.1.3 to-ports=10554 comment="Forward HiK DVR RTSP Server Listen UDP port 2"
```

```sh
# Forward ports 80/443 (tcp)
/ip firewall nat add chain=dstnat protocol=tcp dst-port=80 action=dst-nat to-addresses=192.168.1.3 to-ports=80 comment="Forward HiK DVR HTTP Port"
/ip firewall nat add chain=dstnat protocol=tcp dst-port=443 action=dst-nat to-addresses=192.168.1.3 to-ports=443 comment="Forward HiK DVR HTTPS Port"
```