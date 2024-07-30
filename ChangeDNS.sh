#!/bin/bash

# Define the connection name
CONNECTION_NAME="Wired connection 1"

# Get the current DNS settings
CURRENT_DNS=$(nmcli -g ipv4.dns connection show "$CONNECTION_NAME")

# Check the current DNS and toggle
if [ "$CURRENT_DNS" == "8.8.8.8" ]; then
    NEW_DNS="10.30.50.6"
else
    NEW_DNS="8.8.8.8"
fi

# Set the new DNS
nmcli con mod "$CONNECTION_NAME" ipv4.dns "$NEW_DNS"

# Ignore automatically configured DNS
#nmcli con mod "$CONNECTION_NAME" ipv4.ignore-auto-dns yes

# Apply the changes by bringing the connection down and then up
nmcli con down "$CONNECTION_NAME" && nmcli con up "$CONNECTION_NAME"

echo "DNS changed to $NEW_DNS"

