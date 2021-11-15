#ARG UBUNTU_VERSION=eoan
#FROM ubuntu:$UBUNTU_VERSION
FROM drpsychick/airprint-bridge:latest
MAINTAINER drpsychick@drsick.net

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -y upgrade

# Canon printer driver
RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository ppa:thierry-f/fork-michael-gruz

RUN apt-get -y install \
      cups-daemon \
      cups-client \
      cups-pdf \
      printer-driver-all \
      openprinting-ppds \
      hpijs-ppds \
      hp-ppd \
      hplip \
      avahi-daemon \
      google-cloud-print-connector \
      libnss-mdns \
# for mkpasswd
      whois \
      curl \
      inotify-tools \
      libpng16-16 \
      python3-cups \
      samba-client \
# Canon printer and scanner drivers
      scangearmp2 \
      cnijfilter2 \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# sane-airscan - https://software.opensuse.org//download.html?project=home%3Apzz&package=sane-airscan
RUN echo 'deb http://download.opensuse.org/repositories/home:/pzz/xUbuntu_20.04/ /' >> /etc/apt/sources.list.d/home:pzz.list
RUN curl -fsSL https://download.opensuse.org/repositories/home:pzz/xUbuntu_20.04/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home_pzz.gpg > /dev/null
RUN apt update && apt-get -y install sane-airscan

# TODO: really needed?
COPY mime/ /etc/cups/mime/

# setup airprint and google cloud print scripts
COPY airprint/ /opt/airprint/
COPY gcp-connector /etc/init.d/

# getting error: "useradd: user 'gcp-connector' already exists"
#RUN useradd -s /usr/sbin/nologin -r -M gcp-connector \

RUN mkdir -p /etc/gcp-connector \
    && chown gcp-connector /etc/gcp-connector \
    && chmod +x /etc/init.d/gcp-connector \
    && mkdir -p /var/run/dbus

COPY healthcheck.sh /
COPY start-cups.sh /root/
RUN chmod +x /healthcheck.sh /root/start-cups.sh
HEALTHCHECK --interval=10s --timeout=3s CMD /healthcheck.sh

ENV TZ="GMT" \
    CUPS_ADMIN_USER="admin" \
    CUPS_ADMIN_PASSWORD="secr3t" \
    CUPS_WEBINTERFACE="yes" \
    CUPS_SHARE_PRINTERS="yes" \
    CUPS_REMOTE_ADMIN="yes" \
    CUPS_ENV_DEBUG="no" \
    # defaults to $(hostname -i)
    CUPS_IP="" \
    CUPS_ACCESS_LOGLEVEL="config" \
    # example: lpadmin -p Epson-RX520 -D 'my RX520' -m 'gutenprint.5.3://escp2-rx620/expert' -v smb://user:pass@host/Epson-RX520"
    CUPS_LPADMIN_PRINTER1=""
    AIRSCAN_SUBNET="192.168.0.0/18"

# google cloud print config
# run `gcp-connector-util init` and take the values from the resulting json file
ENV GCP_XMPP_JID="" \
    GCP_REFRESH_TOKEN="" \
    GCP_PROXY_NAME="" \
    GCP_ENABLE_LOCAL="false" \
    GCP_ENABLE_CLOUD="false"

ENTRYPOINT ["/root/start-cups.sh"]
