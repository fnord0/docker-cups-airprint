# Simple AirPrint bridge docker container to be run on QNAP NAS to share a Canon (PIXMA TS5100-series) USB printer

## Purpose
Run a container with CUPS and Avahi (mDNS/Bonjour) so that local printers
on the network can be exposed via AirPrint to iOS/macOS, Windows and Android devices.

## Requirements
* This is forked from [drpsychick/airprint-bridge](https://hub.docker.com/r/drpsychick/airprint-bridge) docker container
* The container must (really, really should) have its own, dedicated IP so it does not interfere with other services listen on the ports required
(macOS: already runs CUPS and mdns, Linux: mostly also already runs CUPS and/or Avahi)

### Hints
* a shared Windows printer must be accessible by anonymous users (without login)
or you must provide a username and password whithin its device URI (`smb://user:pass@host/printer`)

## QNAP TS-453D + Canon PIXMA TS5210 USB
Connect your Canon PIXMA TS5210 printer via USB to the QNAP TS-453D NAS USB port
SSH to your QNAP NAS and run the following commands (pay special attention to *cups_ip*, *subnet*, *gateway* and *CUPS_USER_PASSWORD*)
```
git clone https://github.com/fnord0/docker-cups-airprint.git
cd docker-cups-airprint

docker build -t drpsychick/airprint-bridge .

docker network create --driver=qnet --ipam-driver=qnet --ipam-opt=iface=bond0 --subnet 192.168.1.0/18 --gateway 192.168.1.1 localnet

cups_ip=192.168.1.100
cups_name=cups.home

docker create --name=cups-airprint \
  --net=localnet \
  --ip=$cups_ip \
  --hostname=$cups_name \
  --memory=100M \
  -p 137:137/udp \
  -p 139:139/tcp \
  -p 445:445/tcp \
  -p 631:631/tcp \
  -p 5353:5353/udp \
  -v /var/run/dbus:/var/run/dbus \
  --device /dev/bus \
  --device /dev/usb \
  -e CUPS_USER_ADMIN=admin \
  -e CUPS_USER_PASSWORD="secr3t" \
  drpsychick/airprint-bridge

docker start cups-airprint
```

### Connect to CUPS admin page
Browse to http://192.168.1.100:631/ (specified above as `$cups_ip` / `cups_ip=192.168.1.100` - use port **631**)
- Add your printer
    - My printer showed up in the list as **Canon_TS5100_series**
- Specify your driver, I choose **Canon TS5100 series** driver

### Windows 10x64
Add Printer
- My Canon printer was detected as **AirPrint Canon_TS5100_series @ cups**

### Android
Install [Canon Print Service](https://play.google.com/store/apps/details?id=jp.co.canon.android.printservice.plugin&hl=en_US&gl=US)
- Print in any application and choose **AirPrint Canon_TS5100_series @ cups**

# Credits
This is based on awesome work of others
* https://hub.docker.com/r/drpsychick/airprint-bridge | https://www.github.com/DrPsychick/docker-cups-airprint
* https://hub.docker.com/r/jstrader/airprint-cloudprint/
* https://github.com/tjfontaine/airprint-generate

## See https://hub.docker.com/r/drpsychick/airprint-bridge for more information
