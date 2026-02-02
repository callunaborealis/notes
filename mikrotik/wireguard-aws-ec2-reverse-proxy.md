# Setting up a reverse proxy between AWS EC2 Ubuntu instance to MikroTik router running RouterOS v7.18 via WireGuard

On EC2 running Ubuntu:

```sh
# Set up packages and firewall via ufw
sudo apt update && sudo apt install -y nginx wireguard ufw certbot python3-certbot-nginx
sudo ufw allow 80,443/tcp
# Allow traffic into EC2 via wg port
sudo ufw allow 51820/udp
sudo ufw enable

```

Set up nginx with support for websockets:

```conf
##
## This can't be placed in /etc/nginx/nginx.conf
## because $http_upgrade is not defined in `nginx.conf`
##
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen 80;
    server_name your_server.com;

    location / {
        proxy_pass http://10.200.200.2:3000;

        # ---- websockets ----
        proxy_http_version 1.1;              # keep-alive + WS handshake
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        # ---- Standard reverse proxy headers ----
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Optional: Keep long-lived sockets from timing out
        proxy_read_timeout 60s;
    }
}
```

```sh
sudo ln -s /etc/nginx/sites-available/app.example.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

Add HTTPS:

```sh
sudo certbot --nginx -d app.example.com
```

Set up WireGuard keys and config:

```sh

sudo su # Optional: If we require higher privileges in an EC2 instance to write to `/etc`
cd /etc/wireguard
# Generate wg key pair to connect to MikroTik router
wg genkey | tee ec2_via_wg.key | wg pubkey > ec2_via_wg.pub
# Copy public key
more ec2_via_wg.key
vim wg0.conf
```

In `wg0.conf`, add:

```conf
[Interface]
Address = 10.200.200.1/30
PrivateKey = <MIKROTIK_ROUTER_WG_GEN_PRIVATE_KEY>
ListenPort = 51820
PostUp   = iptables -t nat -A POSTROUTING -s 10.200.200.0/30 -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -s 10.200.200.0/30 -o eth0 -j MASQUERADE

[Peer]
PublicKey = <Content of AWS EC2 /etc/wireguard/>ec2_via_wg.key>
# LAN behind MikroTik
AllowedIPs = 10.200.200.2/32, 192.168.1.0/24
PersistentKeepalive = 25
```

Do not add `Endpoint = <MIKROTIK_ROUTER_PUBLIC_IP>:51820` under the `[Peer]` block since it will take the router IP from the first packet from WireGuard.

Save the configuration file, then lock both the file and key.

```sh
sudo chmod 600 /etc/wireguard/wg0.conf /etc/wireguard/ec2_via_wg.key /etc/wireguard/ec2_via_wg.pub
```

If a `wg0` was already running, restart it:

```sh
sudo systemctl daemon-reload
sudo systemctl restart wg-quick@wg0
sudo systemctl enable  wg-quick@wg0
```

Then verify the WireGuard connection is properly set up. There should be: an interface named `wg0` and peer labelled with the MikroTik WG interface generated public key:

```sh
sudo wg show wg0
# ...should print something like this:
interface: wg0
  public key: <AWS_EC2_WG_GEN_PUBLIC_KEY>
  private key: (hidden)
  listening port: 51820

peer: <MIKROTIK_ROUTER_WG_GEN_PUBLIC_KEY>
  endpoint: <MIKROTIK_ROUTER_PUBLIC_IP>:51820
  allowed ips: 10.200.200.2/32, 192.168.1.0/24
  latest handshake: 3 seconds ago
  transfer: 180 B received, 124 B sent
  persistent keepalive: every 25 seconds

```

In MikroTik, we create a new WireGuard interface (any name, e.g. `ec2_via_wg_interface`)

```sh
# In RouterOS v7, keys will be generated on interface creation
/interface/wireguard add name=ec2_via_wg_interface listen-port=51820 comment="tunnel to ec2 instance"
# Expose <MIKROTIK_ROUTER_WG_GEN_PUBLIC_KEY> to copy into ec2
/interface/wireguard print detail where name=ec2_via_wg_interface
# ...should print:
Flags: X - disabled; R - running 
 0  R ;;; tunnel to ec2 instance
      name="ec2_via_wg_interface" mtu=1420 listen-port=51820 private-key="<MIKROTIK_ROUTER_WG_GEN_PRIVATE_KEY>" public-key="<MIKROTIK_ROUTER_WG_GEN_PUBLIC_KEY>" 
# !! Do note that <MIKROTIK_ROUTER_WG_GEN_PUBLIC_KEY> has an "=" character behind it !!

# Add address to ARP
/ip/address add address=10.200.200.2/30 interface=ec2_via_wg_interface comment="to ec2 instance via wg"
/interface/wireguard/peers add interface=ec2_via_wg_interface name="peer1" public-key="<AWS_EC2_WG_GEN_PUBLIC_KEY>" endpoint-address=<AWS_EC2_PUBLIC_IP> \
    endpoint-port=51820 allowed-address=10.200.200.1/32,0.0.0.0/0 persistent-keepalive=25s

# Add firewall rules (We use "ec2_via_wg_address_list" as the list name)
/ip/firewall/address-list add address=<AWS_EC2_PUBLIC_IP> list=ec2_via_wg_address_list
/ip/firewall/filter add chain=input src-address-list=ec2_via_wg_address_list protocol=udp dst-port=51820 action=accept comment="allow openwebui web app hosted on fragile-aquarium-arch to tx to proxima ec2 instance"

# Check reverse proxy tunnel heath
/interface/wireguard/peers print detail
# ...should print:
Flags: X - disabled; D - dynamic 
 0    interface=ec2_via_wg_interface name="peer1" public-key="<AWS_EC2_WG_GEN_PUBLIC_KEY>" private-key="" endpoint-address=<AWS_EC2_PUBLIC_IP> endpoint-port=51820 
      current-endpoint-address=<AWS_EC2_PUBLIC_IP> current-endpoint-port=51820 allowed-address=10.200.200.1/32,0.0.0.0/0 preshared-key="" persistent-keepalive=25s client-endpoint="" 
      rx=0 tx=55.1KiB 

```

Now enable `wg-quick` whenever the ec2 instance spins up:

Expose the LAN service internally on the MikroTik router:

`DST_NAT_HOST_IP` is [the destination network address translated internal host IP address connected locally to the MikroTik router](https://wiki.mikrotik.com/Manual:IP/Firewall/NAT#Destination_NAT), e.g. `192.168.1.50`. It could be a gaming server, web server etc.

```sh
/ip/firewall/nat add chain=dstnat src-address=10.200.200.1 protocol=tcp dst-port=3000 action=dst-nat to-address=<DST_NAT_HOST_IP> to-ports=3000 comment="aws ec2 reverse proxy upstream"
# Optional (see below): Add hairpin rule to support TCP handshake with WG, especially
# if Mikrotik router drops anything not coming from 192.168.1.0/24 (as it does by default)
# Remember to move this above just below the original NAT rule
/ip/firewall/nat add chain=srcnat src-address=10.200.200.0/30  dst-address=<DST_NAT_HOST_IP> protocol=tcp dst-port=3000  out-interface=bridge action=masquerade comment="masquerade aws ec2 reverse proxy upstream"
# Add firewall rules
/ip/firewall/filter add chain=input in-interface=ec2_via_wg_interface src-address=10.200.200.1 protocol=icmp action=accept comment="allow ping from aws ec2 instance via wg"  
/ip/firewall/filter add chain=input in-interface=ec2_via_wg_interface src-address=10.200.200.1 protocol=tcp dst-port=3000 action=accept comment="allow DST_NAT_HOST_IP to tx to aws ec2 instance"
/ip/firewall/filter add chain=forward in-interface=ec2_via_wg_interface src-address=10.200.200.1 dst-address=<DST_NAT_HOST_IP> protocol=tcp dst-port=3000 action=accept comment="forward wg to DST_NAT_HOST_IP server app"
```

<hr />

**Optional:** Support handshake between WireGuard and <DST_NAT_HOST_IP> host on the MikroTik Router

In the event the connection between WireGuard and the <DST_NAT_HOST_IP> host has problems, debug the connections by:

```sh
# On AWS EC2, ping the MikroTik router via WireGuard
curl -I --max-time 5 http://10.200.200.2:3000
```

```sh
# On MikroTik, simulateneously listen for the TCP handshake rows coming from WireGuard
/tool/sniffer/quick interface=all port=3000
```

If SYN (synchronize) TCP packets are arriving from `ec2_via_wg_interface`, are DNAT-ed and forwarded out via `bridge` or other router interfaces into local destination IP, but the MikroTik router does not send back another TCP packet (e.g. `SYN-ACK` or `RST`) back to the AWS EC2 instance, check the firewall of the MikroTik router.

Finally, on the `DST_NAT_HOST_IP`, if there is any firewall set up (e.g. `ufw`), ensure packets can be sent back to the aws ec2 instance:

```sh
# 192.168.1.0/24 here is the gateway IP  for 192.168.1.50 (if a custom network IP is used, use it:
# e.g. 192.168.2.100 -> 192.168.2.0/24 (with the last octet as `0` should be used)
sudo ufw allow proto tcp from 192.168.1.0/24 to any port 3000
sudo ufw allow proto tcp from 10.200.200.0/30 to any port 3000
```

<hr />

Once done, start WireGuard on your EC2 instance:
```sh
sudo systemctl enable --now wg-quick@wg0
```

Verify that the reverse proxy to the MikroTik router is set up:

```sh
interface: wg0
  public key: ewP3qW4BlI5Mq+h29RS76ARdRzo7QI3PhKOUuxrNDW8=
  private key: (hidden)
  listening port: 51820

peer: whkgytbA0wg4/SE4AyK7VFBqxHltBF0yz+2DJ3/38go=
  endpoint: 58.182.191.128:51820
  allowed ips: 10.200.200.2/32, 192.168.1.0/24
  latest handshake: 3 seconds ago
  transfer: 180 B received, 124 B sent
  persistent keepalive: every 25 seconds
```
