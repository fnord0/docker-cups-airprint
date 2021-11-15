# Simple AirPrint bridge docker container to be run on QNAP NAS to share a Canon (PIXMA TS5100-series) USB printer+scanner

## Purpose
Run a container with CUPS and Avahi (mDNS/Bonjour) so that local printers 
on the network can be exposed via AirPrint to iOS/macOS, Windows and Android devices.
Also AirScan is utilized for network-based scanning. This docker image is custom-built 
for Canon printers and scanners. I am specifically using a Canon PIXMA TS5120 printer+scanner.

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
$ docker network create --driver=qnet --ipam-driver=qnet --ipam-opt=iface=bond0 --subnet 192.168.0.0/18 --gateway 192.168.1.1 qnet-static

$ git clone https://github.com/fnord0/docker-cups-airprint.git
$ cd docker-cups-airprint

$ docker build -t drpsychick/airprint-bridge:latest .
```
This will build the image locally, which is the HIGHLY suggested way to get the latest packages, security fixes, and to be sure it is built the way you want (pleaes review the file: `Dockerfile` to see exactly what is going on during the build).

## Docker Create
Create a Docker container running cups/airprint and airscan:
```
$ cups_ip=192.168.1.100
$ cups_name=cups.home

$ docker create \
       --name=cups-airprint \
       --restart=always \
       --net=qnet-static \
       --ip=$cups_ip \
       --hostname=$cups_name \
       -p 137:137/udp \
       -p 139:139/tcp \
       -p 445:445/tcp \
       -p 631:631/tcp \
       -p 5353:5353/udp \
       -v /var/run/dbus:/var/run/dbus \
       -v /share/docker-data/airprint_data/config:/config \
       -v /share/docker-data/airprint_data/services:/services \
       --device /dev/bus \
       --device /dev/usb \
       -e CUPS_USER_ADMIN=admin \
       -e CUPS_USER_PASSWORD="secr3t" \
       -e CUPS_IP=${cups_ip} \
       -e CUPS_HOSTNAME=${cups_name} \
       -e CUPS_SHARE_PRINTERS=yes \
       -e CUPS_REMOTE_ADMIN=yes \
       drpsychick/airprint-bridge:latest
```
To start the container
```
$ docker start cups-airprint
```
To stop the container
```
$ docker stop cups-airprint
```
To remove the conainer simply run:
```
$ docker rm cups-airprint
```

+ **Notes**: The `Dockerfile` explicitly sets volumes at `/config` and
`/services` inside the container as mount points. Here we actually override the default
use of Docker's innate volume management system and declare our own path on the
host system to mount the two directories `/config` and `/services`. Why? Because
now if the container is deleted (for any number of reason ...) the data will
persist. Here we chose to mount the internal `/config` and `/services`
directories to `/share/docker-data/airprint_data/config` and `/share/docker-data/airprint_data/services`
respectively, but these could just as well be anywhere on your file system. See for reference
[Docker Volumes](https://docs.docker.com/storage/volumes/).

### Parameters
* `--name`: gives the container a name making it easier to work with/on (e.g.
  `cups-airprint`)
* `--restart`: restart policy for how to handle restarts (e.g. `always` restart)
* `--net`: network to join (e.g. the `qnet-static` network) which we created earlier during the 
  `docker network create ....` command
* `-v /share/docker-data/airprint_data/config:/config`: where the persistent printer configs
   will be stored
* `-v /share/docker-data/airprint_data/services:/services`: where the Avahi service files will
   be generated
* `-e CUPS_USER_ADMIN`: the CUPS admin user you want created
* `-e CUPS_USER_PASSWORD`: the password for the CUPS admin user
* `-e CUPS_IP=${cups_ip}`: the static IP address of the CUPS server we configured before running `docker create`, make sure it is part of the `--subnet` (example: `192.168.0.0/18`) used when we ran the earlier command to create the docker network `docker network create ...`
* `-e CUPS_HOSTNAME=${cups_name}`: the hostname you wish to call the CUPS server, also configured before running `docker create`
* `-e CUPS_SHARE_PRINTERS=yes`: do you want your CUPS printer to share printers by default, `yes` OR `no`
* `-e CUPS_REMOTE_ADMIN=yes`: do you want your CUPS docker container to be remotely administrated, `yes` OR `no`
* `--device /dev/bus`: device mounted for interacting with USB printers
* `--device /dev/usb`: device mounted for interacting with USB printers

## Docker Compose
If you don't want to type out these long **Docker** commands, you could
optionally use [docker-compose](https://docs.docker.com/compose/) to set up your
image. Just download the repo and run it like so:
```
$ git clone https://github.com/fnord0/docker-cups-airprint.git
$ cd docker-cups-airprint
$ docker-compose up --build
```
NOTE: This compose file is made with `USB` printers in mind and like the above commands has 
`device` mounts for `USB` printers. If you don't have a `USB` printer you may want to comment 
these out. Also the `config/services` data will be saved to the `/share/docker-data/airprint_data/services`
directory. Again you may want to edit this to your own liking.

## [QNAP Container Station](https://www.qnap.com/en/how-to/tutorial/article/how-to-use-container-station)
If you would like to build the Docker container via the [QNAP Container Station](https://www.qnap.com/en/how-to/tutorial/article/how-to-use-container-station) GUI utilize the following instructions. Be aware how Applications work - just for reference here is an example of how a [Gitea server](https://www.anchorpoint.app/blog/setting-up-a-self-hosted-git-server) would be setup through QNAP Container Station as an Application.
- Make sure you've already created a Docker network, checked out this repo and ran the build process as specified at the top of this document.
- Launch **Container Station**, click **Create** on the *left*
- Click **Create Application**
- Paste the following Docker-compose code (*no TABS*) into the Create Application window
```
version: "2.4"

services:
  cups-airprint:
    container_name: cups-airprint
    image: drpsychick/airprint-bridge:latest
    networks:
      qnet-static:
        ipv4_address: 192.168.1.100
    ports:
      - "137:137"
      - "139:139"
      - "445:445"
      - "631:631"
      - "5353:5353"
      - "6566:6566"
    volumes:
      - /var/run/dbus:/var/run/dbus
      - /share/docker-data/airprint_data/config:/config
      - /share/docker-data/airprint_data/services:/services
    devices:
      - /dev/bus
      - /dev/usb
    restart: always
    environment:
      - TZ=PST
      - CUPS_USER_ADMIN=admin
      - CUPS_USER_PASSWORD=secr3t
      - CUPS_IP=192.168.1.100
      - CUPS_HOSTNAME=cups.home
      - CUPS_WEBINTERFACE=yes
      - CUPS_SHARE_PRINTERS=yes
      - CUPS_REMOTE_ADMIN=yes

networks:
  qnet-static:
    external: true
```
- Click **Validate YAML** button
- Click **Create** button
- Wait for the Application to launch properly

## Using
### Connect to CUPS admin page
Browse to http://192.168.1.100:631/ (specified above as `$cups_ip` / `cups_ip=192.168.1.100`) - use port **631**
- Add your printer
    - My printer showed up in the list as Name: **Canon_TS5100_series**
    - Specify your model/driver, I choose **Canon TS5100 series Ver.5.50 (en, de, fr, zh, ja)** model/driver

### [sane-airscan](https://github.com/alexpevzner/sane-airscan) / [saned](https://help.ubuntu.com/community/sane)
- Your scanner should be automatically shared on the network via port 6656. Try to using [a tool listed here](http://www.sane-project.org/sane-frontends.html), I personally like [SaneTwain](https://sanetwain.ozuzo.net/).
- Review the **Dockerfile** where the `/etc/sane.d/saned.conf` is getting configured using these lines:
    ```
    RUN echo 'localhost' >> /etc/sane.d/saned.conf
    RUN echo '192.168.0.0/18' >> /etc/sane.d/saned.conf
    ```
- Ideally, you will want to modify the subnet `192.168.0.0/18` to the subnet you intend to use on your server/NAS.

### Windows 10x64
Add Printer
- My Canon printer was detected as **AirPrint Canon_TS5100_series @ cups**, it was found automatically
    - It is also directly addressible via `http://192.168.1.100:631/printers/Canon_TS5100_series`

### Android
Install [Canon Print Service](https://play.google.com/store/apps/details?id=jp.co.canon.android.printservice.plugin&hl=en_US&gl=US)
- Print in any application and choose **AirPrint Canon_TS5100_series @ cups**

# Credits
This is based on awesome work of others
* https://hub.docker.com/r/drpsychick/airprint-bridge | https://www.github.com/DrPsychick/docker-cups-airprint
* https://hub.docker.com/r/jstrader/airprint-cloudprint/
* https://github.com/tjfontaine/airprint-generate

## See https://hub.docker.com/r/drpsychick/airprint-bridge for more information
