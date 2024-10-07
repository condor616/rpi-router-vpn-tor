#!/bin/bash

# switch_mode.sh
# CGI script to handle network mode switching

echo "Content-type: text/html"
echo ""

read -n $CONTENT_LENGTH POST_DATA

MODE=$(echo "$POST_DATA" | sed -n 's/^mode=$begin:math:text$.*$end:math:text$$/\1/p' | tr '+' ' ')

if [ "$MODE" = "Switch to ProtonVPN" ]; then
    sudo /usr/local/bin/switch_to_vpn.sh
    MESSAGE="Switched to ProtonVPN."
elif [ "$MODE" = "Switch to Tor" ]; then
    sudo /usr/local/bin/switch_to_tor.sh
    MESSAGE="Switched to Tor."
else
    MESSAGE="Unknown mode."
fi

cat <<EOT
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Network Mode Switcher</title>
    <!-- Bootstrap CSS -->
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
</head>
<body>

<div class="container mt-5 text-center">
    <div class="alert alert-info" role="alert">
        <h4 class="alert-heading">$MESSAGE</h4>
    </div>
    <a href="index.sh" class="btn btn-primary">Go Back</a>
</div>

<!-- jQuery and Bootstrap JS -->
<script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.bundle.min.js"></script>
</body>
</html>
EOT