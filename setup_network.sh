#!/bin/bash

# setup_network.sh
# Automated setup script for Raspberry Pi VPN/Tor Wireless Access Point

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root. Use sudo ./setup_network.sh" 1>&2
   exit 1
fi

# Load SSID and encrypted passphrase from config.txt
CONFIG_FILE="config.txt"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Decrypt the passphrase
if [ -f "/root/.wifi_key" ] && [ -n "$PASSPHRASE_ENC" ]; then
    PASSPHRASE=$(echo "$PASSPHRASE_ENC" | openssl enc -aes-256-cbc -d -a -salt -pass file:/root/.wifi_key 2>/dev/null)
else
    PASSPHRASE="password1234"
fi

# If SSID is empty, set default value
if [ -z "$SSID" ]; then
    SSID="SetupNetwork"
fi

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing necessary packages..."
apt install -y hostapd dnsmasq iptables-persistent openvpn tor lighttpd lighttpd-mod-cgi apache2-utils openssl

echo "Stopping services to configure them..."
systemctl stop hostapd
systemctl stop dnsmasq

echo "Configuring static IP address for wlan0..."
cat >> /etc/dhcpcd.conf <<EOF
interface wlan0
    static ip_address=192.168.50.1/24
    nohook wpa_supplicant
EOF

echo "Configuring DHCP server (dnsmasq)..."
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig 2>/dev/null
cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
dhcp-range=192.168.50.2,192.168.50.50,255.255.255.0,24h
EOF

echo "Configuring hostapd..."
cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211
ssid=$SSID
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSPHRASE
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|g' /etc/default/hostapd

echo "Enabling IP forwarding..."
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|g' /etc/sysctl.conf
sysctl -p

echo "Configuring NAT with iptables..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sh -c "iptables-save > /etc/iptables/rules.v4"

echo "Starting services..."
systemctl unmask hostapd
systemctl enable hostapd dnsmasq
systemctl restart hostapd dnsmasq

echo "Setting up ProtonVPN..."

# Install ProtonVPN CLI
echo "Installing ProtonVPN CLI..."
wget -q -O - https://protonvpn.com/download/protonvpn-public.asc | apt-key add -
echo 'deb https://repo.protonvpn.com/debian unstable main' > /etc/apt/sources.list.d/protonvpn.list
apt update
apt install -y protonvpn-cli

echo "Please log in to ProtonVPN CLI..."
protonvpn-cli login

echo "Configuring Tor..."
cat >> /etc/tor/torrc <<EOF

# Added by setup script
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 9040
DNSPort 5353
EOF

systemctl restart tor

echo "Creating switch scripts..."

# Copy switch scripts
cp scripts/switch_to_vpn.sh /usr/local/bin/switch_to_vpn.sh
cp scripts/switch_to_tor.sh /usr/local/bin/switch_to_tor.sh

chmod +x /usr/local/bin/switch_to_vpn.sh
chmod +x /usr/local/bin/switch_to_tor.sh

echo "Setting up web interface..."

# Enable CGI module
lighty-enable-mod cgi
systemctl restart lighttpd

# Secure the web interface
htpasswd -c /etc/lighttpd/.lighttpdpassword admin

# Configure Lighttpd for authentication
if ! grep -q "/admin/" /etc/lighttpd/lighttpd.conf; then
cat >> /etc/lighttpd/lighttpd.conf <<EOF

# Added by setup script
\$HTTP["url"] =~ "^/admin/" {
    auth.backend = "htpasswd"
    auth.backend.htpasswd.userfile = "/etc/lighttpd/.lighttpdpassword"
    auth.require = ( "" => (
        "method"  => "basic",
        "realm"   => "Admin Area",
        "require" => "valid-user"
    ))
}
EOF
fi

systemctl restart lighttpd

# Create admin directory
mkdir -p /var/www/html/admin

# Copy web interface files
cp web_interface/index.sh /var/www/html/admin/index.sh
cp web_interface/switch_mode.sh /var/www/html/admin/switch_mode.sh
cp web_interface/style.css /var/www/html/admin/style.css
cp web_interface/setup.sh /var/www/html/setup.sh

chmod +x /var/www/html/admin/index.sh
chmod +x /var/www/html/admin/switch_mode.sh
chmod +x /var/www/html/setup.sh

# Set permissions
chown -R www-data:www-data /var/www/html/admin
chown www-data:www-data /var/www/html/setup.sh
chmod -R 750 /var/www/html/admin
chmod 750 /var/www/html/setup.sh

# Configure sudoers for www-data
echo "Configuring sudoers for web interface..."
cat > /etc/sudoers.d/www-data <<EOF
www-data ALL=(ALL) NOPASSWD: /usr/local/bin/switch_to_vpn.sh
www-data ALL=(ALL) NOPASSWD: /usr/local/bin/switch_to_tor.sh
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart hostapd
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart dnsmasq
EOF

echo "Configuring Lighttpd to recognize index.sh and setup.sh..."
sed -i 's/index.lighttpd.html/index.sh index.html/g' /etc/lighttpd/lighttpd.conf

systemctl restart lighttpd

# Generate encryption key if it doesn't exist
if [ ! -f "/root/.wifi_key" ]; then
    openssl rand -base64 32 > /root/.wifi_key
    chmod 600 /root/.wifi_key
fi

echo "Setup complete!"

if [ "$SSID" = "SetupNetwork" ] && [ "$PASSPHRASE" = "password1234" ]; then
    echo "Please connect to the 'SetupNetwork' Wi-Fi network and navigate to http://192.168.50.1/setup.sh to complete the configuration."
else
    echo "Please connect to your Wi-Fi network '$SSID' using the passphrase you provided."
    echo "Access the admin interface at http://[Your_Raspberry_Pi_IP_Address]/admin/"
fi

echo "Remember to:"
echo "- Secure your ProtonVPN credentials and consider using the keychain method for ProtonVPN CLI."
echo "- Change the admin password for the web interface using 'htpasswd /etc/lighttpd/.lighttpdpassword admin'."