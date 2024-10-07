#!/bin/bash

# switch_to_vpn.sh
# Script to switch network mode to ProtonVPN

# Stop Tor
systemctl stop tor

# Disconnect ProtonVPN if already connected
protonvpn-cli disconnect

# Connect to ProtonVPN (fastest server)
protonvpn-cli c -f

# Flush iptables
iptables -F
iptables -t nat -F

# Enable forwarding
sysctl -w net.ipv4.ip_forward=1

# Set up NAT
VPN_IF="proton0"
iptables -t nat -A POSTROUTING -o $VPN_IF -j MASQUERADE
iptables -A FORWARD -i wlan0 -o $VPN_IF -j ACCEPT
iptables -A FORWARD -i $VPN_IF -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Update current mode
echo "VPN" > /var/www/html/admin/current_mode.txt

echo "Switched to ProtonVPN."