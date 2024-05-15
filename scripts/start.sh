#!/bin/bash

set -ex

chown -R root:video /dev/dri
chmod -R 770 /dev/dri

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

# Mask the service, making it point to /dev/null
DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket \
  dbus-send \
  --system \
  --print-reply \
  --dest=org.freedesktop.systemd1 \
  /org/freedesktop/systemd1 \
  org.freedesktop.systemd1.Manager.MaskUnitFiles \
  array:string:"serial-getty@serial0.service" \
  boolean:true \
  boolean:true

# Stop the service.
# Details about the second parameter: 
#> The mode needs to be one of replace, fail, isolate, ignore-dependencies,
#> ignore-requirements. If "replace" the call will start the unit and its
#> dependencies, possibly replacing already queued jobs that conflict with this.
DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket \
  dbus-send \
  --system \
  --print-reply \
  --dest=org.freedesktop.systemd1 \
  /org/freedesktop/systemd1 \
  org.freedesktop.systemd1.Manager.StopUnit \
  string:"serial-getty@serial0.service" \
  string:replace

# Load kernel module for exfat
/sbin/modprobe exfat

rm -rf /tmp/DMXCore100Temp/devices

# Trigger udev rules
if which udevadm > /dev/null; then
  set +e # Disable exit on error
  service udev restart
  udevadm control --reload-rules
  service udev restart
  udevadm trigger
  set -e # Re-enable exit on error
fi

# /bin/udevadm trigger --action=add --subsystem-match=block

echo 200 > /proc/sys/net/ipv4/igmp_max_memberships

mkdir -p /root/VSLinuxDbg/DMXCore100
cp /usr/src/scripts/r.sh /root/VSLinuxDbg/r
cp /usr/src/scripts/c.sh /root/VSLinuxDbg/c
cp /usr/src/scripts/x.sh /root/VSLinuxDbg/x

if [ ! -e "/data/dmxcore100.key" ]; then
	PARENT="dmxcore100"
	openssl req \
	-x509 \
	-newkey rsa:4096 \
	-sha256 \
	-days 3650 \
	-nodes \
	-keyout /data/dmxcore100.key \
	-out /data/dmxcore100.crt \
	-subj "/CN=dmxcore100" \
	-extensions v3_ca \
	-extensions v3_req \
	-config <( \
	  echo '[req]'; \
	  echo 'default_bits= 4096'; \
	  echo 'distinguished_name=req'; \
	  echo 'x509_extension = v3_ca'; \
	  echo 'req_extensions = v3_req'; \
	  echo '[v3_req]'; \
	  echo 'basicConstraints = CA:FALSE'; \
	  echo 'keyUsage = nonRepudiation, digitalSignature, keyEncipherment'; \
	  echo '[ v3_ca ]'; \
	  echo 'subjectKeyIdentifier=hash'; \
	  echo 'authorityKeyIdentifier=keyid:always,issuer'; \
	  echo 'basicConstraints = critical, CA:TRUE, pathlen:0'; \
	  echo 'keyUsage = critical, cRLSign, keyCertSign'; \
	  echo 'extendedKeyUsage = serverAuth, clientAuth')

	openssl x509 -noout -text -in /data/dmxcore100.crt
fi

export XDG_RUNTIME_DIR="/tmp/displayserver/.wayland"

# Cleanup
rm -rf /tmp/displayserver/*
rm -rf /tmp/displayserver/.*
rm -f /run/seatd.sock
# Creating new directories
mkdir -p "$XDG_RUNTIME_DIR"
# Setting permissions
chmod 0700 "$XDG_RUNTIME_DIR"
chown -R displayuser:displayuser /tmp/displayserver

# First switch back to vt1
chvt 1
# Run display init on vt7
openvt -c 7 -f -- /usr/src/scripts/display-init.sh $(tty)

while true; do
	file_path=$(find "$XDG_RUNTIME_DIR" -type s -name "sway-ipc.*" -print -quit)

	if [ -n "$file_path" ]; then
		echo "Found sway socket: $file_path"
		break
	else
		echo "Waiting for sway socket..."
		sleep 1
	fi
done

# Function to create a device node if it doesn't exists
create_device_node() {
    if [ ! -e "/dev/$1" ]; then
		mknod -m 660 "/dev/$1" b $2 $3
    fi
}

create_device_node sda 8 0
create_device_node sda1 8 1
create_device_node sda2 8 2
create_device_node sda3 8 3
create_device_node sda4 8 4

create_device_node sdb 9 0
create_device_node sdb1 9 1
create_device_node sdb2 9 2
create_device_node sdb3 9 3
create_device_node sdb4 9 4

export XDG_RUNTIME_DIR=/tmp/displayserver/.wayland
export WAYLAND_DISPLAY=$(find $XDG_RUNTIME_DIR/ -name "wayland-*" -not -name "*.lock" | head -n 1 | cut -d "/" -f 5)
export SWAYSOCK=$(find $XDG_RUNTIME_DIR/ -name "sway-ipc.*" | head -n 1)
export GDK_BACKEND=x11
export DISPLAY=:0

/usr/sbin/sshd -p 22 -o "SetEnv=BALENA_SUPERVISOR_ADDRESS=$BALENA_SUPERVISOR_ADDRESS BALENA_SUPERVISOR_API_KEY=$BALENA_SUPERVISOR_API_KEY BALENA_APP_ID=$BALENA_APP_ID BALENA_API_KEY=$BALENA_API_KEY BALENA_DEVICE_UUID=$BALENA_DEVICE_UUID XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR WAYLAND_DISPLAY=$WAYLAND_DISPLAY SWAYSOCK=$SWAYSOCK DISPLAY=$DISPLAY GDK_BACKEND=$GDK_BACKEND"

echo "sleeping!"
sleep infinity

