# Support multiple SSIDs using virtual WLANs on a single MikroTik network device running RouterOS

**Tested with:** [MikroTik hAP ac²](https://mikrotik.com/product/hap_ac2) running RouterOS v6.49.15 stable

Log into **WebFig** via your `admin` credentials.

## Create wireless interface

Under "Wireless" left tab, select "WiFi interfaces" top tab (e.g. `{mikrotik-device-ip}/webfig/#Wireless.WiFi_Interfaces`).

Select the dropdown "Add new" and click on "Virtual". This will open the "Wireless" form (e.g. `{mikrotik-device-ip}/webfig/#Interfaces.Interface.new.Virtual`):

Optional:
- Under "Name" field, rename `wlanx`, where `x` is auto generated numeral, e.g. `wlan3`, to `wlanyv1` (e.g. `wlan1v1`). Not necessary at all, just a personal preference
- Under "Security Profile", change "default" security profile to another. This will allow the new virtual WLAN to use different passwords. To create security profiles, see [Wi-Fi Passwords](./ssid-passwords.md).

Ensure "Master Interface" is `wlany`, where `y` is an existing wlan numeral, e.g. `wlan1`, `wlan2`. By default, this should correspond to 2.4GHz and 5GHz actual bands respectively.

Ensure "Mode" field is the same as `wlany`. So if `wlany` is `ap bridge`, ensure `wlanyv1` is `ap bridge`.

Leave all other default settings unmodified, then click "OK".

## Create ports for each interface on the bridge

Clicking on "Bridge" left tab will open the "Bridge" top tab by default.

By default, there should only be 1 bridge (i.e. `bridgeLocal`). Creating new bridges is possible but currently not tested.

Under "Bridge" left tab, select "Ports" top tab (e.g. `{mikrotik-device-ip}/webfig/#Bridge.Bridge`).

Click on "Add New".

Under the "Interface" field, select the newly created virtual WLAN interface, e.g. `wlanyv1`.
Under the "Bridge" field, ensure `bridgeLocal` is selected.

Leave all other default settings unmodified, then click "OK".

## Create interface

Under "Interfaces" left tab, select "Interface" top tab (e.g. `{mikrotik-device-ip}/webfig/#Interfaces.Interface`). Ensure newly created virtual WLAN `wlanyv1` is in the list.

Under "Interfaces" left tab, select "Interface" top tab (e.g. `{mikrotik-device-ip}/webfig/#Interfaces.Interface_List`). Click on "Add New". Under the "List" field, select "LAN". Ensure under the "Interface" field, the same bridge interface is selected, which is `"bridgeLocal"` by default.

Leave all other default settings unmodified, then click "OK".

## Conclusion

Finally, connect your client to the newly created SSID that should be discoverable (unless the virtual WLAN is hidden / disabled when creating it).

## References

- [Router OS Wiki: Wireless > Wi-Fi](https://help.mikrotik.com/docs/display/ROS/WiFi)
