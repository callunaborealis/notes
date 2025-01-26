# Enabling subnet AirPrint, Bonjour, mDNS

## RouterOS >= v7.16

mDNS is supported natively via v7.16.

Go to IP > DNS and select an interface (e.g. bridge) to enable a mDNS Repeater.

## RouterOS 

```sh
/ip firewall filter add chain=input protocol=udp dst-port=5353 action=accept comment="accept mDNS connections for Apple Bonjour (AirPrint)"
```

```sh
/ip firewall filter add chain=forward protocol=udp dst-port=5353 action=accept comment="forward mDNS connections for Apple Bonjour (AirPrint)"
```