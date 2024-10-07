#!/bin/bash

# setup.sh
# Web interface for initial SSID and passphrase setup

echo "Content-type: text/html"
echo ""

read -n $CONTENT_LENGTH POST_DATA

if [ -z "$POST_DATA" ]; then
    # Display the setup form
    cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Initial Setup</title>
    <link rel="stylesheet" href="admin/style.css">
</head>
<body>

<div class="container">
    <h1>Initial Setup</h1>
    <form action="setup.sh" method="post">
        <label for="ssid">Wi-Fi Network Name (SSID):</label>
        <input type="text" id="ssid" name="ssid" required>

        <label for="passphrase">Wi-Fi Password:</label>
        <input type="password" id="passphrase" name="passphrase" required>

        <button type="submit">Save Settings</button>
    </form>
</div>

</body>
</html>
EOF
else
    # Process the submitted data
    SSID=$(echo "$POST_DATA" | sed -n 's/^.*ssid=$begin:math:text$[^&]*$end:math:text$.*$/\1/p' | sed 's/%20/ /g' | sed 's/+/ /g' | sed 's/%$begin:math:text$..$end:math:text$/\\x\1/g' | xargs -0 printf '%b')
    PASSPHRASE=$(echo "$POST_DATA" | sed -n 's/^.*passphrase=$begin:math:text$[^&]*$end:math:text$.*$/\1/p' | sed 's/%20/ /g' | sed 's/+/ /g' | sed 's/%$begin:math:text$..$end:math:text$/\\x\1/g' | xargs -0 printf '%b')

    # Encrypt the passphrase
    if [ ! -f "/root/.wifi_key" ]; then
        sudo openssl rand -base64 32 > /root/.wifi_key
        sudo chmod 600 /root/.wifi_key
    fi

    PASSPHRASE_ENC=$(echo "$PASSPHRASE" | openssl enc -aes-256-cbc -a -salt -pass file:/root/.wifi_key)

    # Save to config.txt
    echo "SSID=\"$SSID\"" > config.txt
    echo "PASSPHRASE_ENC=\"$PASSPHRASE_ENC\"" >> config.txt

    # Update hostapd configuration
    sudo sed -i "s/^ssid=.*/ssid=$SSID/" /etc/hostapd/hostapd.conf
    # Decrypt passphrase for hostapd
    PASSPHRASE_DEC=$(echo "$PASSPHRASE_ENC" | openssl enc -aes-256-cbc -d -a -salt -pass file:/root/.wifi_key 2>/dev/null)
    sudo sed -i "s/^wpa_passphrase=.*/wpa_passphrase=$PASSPHRASE_DEC/" /etc/hostapd/hostapd.conf

    # Restart services
    sudo systemctl restart hostapd
    sudo systemctl restart dnsmasq

    # Display success message
    cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Setup Complete</title>
    <link rel="stylesheet" href="admin/style.css">
</head>
<body>

<div class="container">
    <h1>Setup Complete</h1>
    <p>Your Wi-Fi network has been configured.</p>
    <p>SSID: <strong>$SSID</strong></p>
    <p>Please reconnect to the new Wi-Fi network.</p>
</div>

</body>
</html>
EOF
fi