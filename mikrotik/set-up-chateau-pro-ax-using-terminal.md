# Set up Chateau Pro ax using Terminal

## Set date and time manually

```bash
# Set timezone
/system clock set time-zone-name=$REGION/$CITY
# Set time
/system clock set time=$HH:$MM:$SS date=$MM/$DD/$YYYY
# Sync time with NTP server
/system ntp client set enabled=yes primary-ntp=pool.ntp.org
# Display current time, date and TZ
/system clock print
```

## Create a user account

```bash
# Print default groups
/user group print
# For groups:
# full - all privileges
# read - read access only
# write - write access
/user add name="$NEW_USERNAME" password="$NEW_PASSWORD" group=full
# Remove default admin account due to prevent issue from CVE-2023-32154
/user remove [find="admin"]
```

## Log out and login with the new user account

```bash
/logout
login
```

## Change identity of the router

```bash
/system identity set name="$ROUTER_NAME"
/system identity print
```

## Set a security profile

Security profiles are a little flakey. Will need to experiment more on this.

```bash
# Update default security profile
/interface wireless security-profiles set [find default=yes] authentication-types=wpa2-psk wpa2-pre-shared-key="$WIFI_PSK"

/interface wireless security-profiles add name=$SECURITY_PROFILE_NAME mode=dynamic-keys authentication-types=wpa3-psk,wpa2-psk encryption=ccmp,gcmp,ccmp-256,gcmp-256 group-encryption=gcmp wpa2-pre-shared-key="$WIFI_PSK" wpa3-pre-shared-key="$WIFI_PSK"

```

## Set up a VLAN interface

```bash
/interface vlan add name="$VLAN_NAME" vland-id=10 interface=ether1
```