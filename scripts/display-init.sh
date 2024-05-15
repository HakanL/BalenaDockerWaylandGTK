#!/bin/bash

echo "Hello from display init" >> $1

export XDG_RUNTIME_DIR="/tmp/displayserver/.wayland"
export WLR_LIBINPUT_NO_DEVICES=1

echo "Setting up sockets and permissions" >> $1
mkdir -p /tmp/.X11-unix
chmod a+wt /tmp/.X11-unix
chmod a+s /usr/bin/seatd-launch

# Get the current hostname
current_hostname=$(hostname)

# Define the IP address for the current hostname (usually 127.0.0.1)
ip_address="127.0.0.1"

# Check if the hostname is already in /etc/hosts
if ! grep -q "$current_hostname" /etc/hosts; then
    # Add the hostname to /etc/hosts
    echo "$ip_address $current_hostname" | tee -a /etc/hosts
fi

while true
do
  chvt 7
  echo "Starting Sway..." >> $1
  sudo -E -u displayuser -- seatd-launch -- /usr/bin/sway -c /app/sway.cfg 2>&1 | tee -a $1
  echo "Sway crashed or exited!" >> $1
  chvt 1
  sleep 5
done
