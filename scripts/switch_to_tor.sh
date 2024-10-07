#!/bin/bash

# switch_to_tor.sh
# Script to switch network mode to Tor

# Disconnect ProtonVPN
protonvpn-cli disconnect

# Start Tor
systemctl start tor

# Flush iptables
iptables -F
iptables -t nat -F

# Enable forwarding
sysctl -w net.ipv4.ip_forward=1

# Redirect traffic through Tor
LAN_IF="wlan0"
TRANS_PORT="9040"
DNS_PORT="5353"

iptables -t nat -A PREROUTING -i $LAN_IF -p udp --dport 53 -j REDIRECT --to-ports $DNS_PORT
iptables -t nat -A PREROUTING -i $LAN_IF -p tcp --syn -j REDIRECT --to-ports $TRANS_PORT

# Update current mode
echo "Tor" > /var/www/html/admin/current_mode.txt

echo "Switched to Tor."