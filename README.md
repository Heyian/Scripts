# Scripts
Personal scripts
This is a repo with many of my personal scripts.

## Bash
- healthcheck.sh
This script will send a ping to Healthcheck.io, must be configured after backup in Duplicati.
- Change_plymouth_theme.sh
This script will change the plymouth theme using [Dracut](https://github.com/dracut-ng/dracut-ng/wiki)
- get_external_ip.sh
This script will fetch your external ip with [Ifconfig.me](http://ifconfig.me) and dump it in a textfile at `/var/log/externalip.log`
This script is used in conjunction with `get_dns_and_external_ip.sh` which is a [Waybar](https://github.com/Alexays/Waybar) custom script to show the current DNS provider and the external IP in the infotip
