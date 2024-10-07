#!/bin/bash

# index.sh
# Web interface for network mode switching

echo "Content-type: text/html"
echo ""

MODE=$(cat /var/www/html/admin/current_mode.txt 2>/dev/null || echo "Unknown")

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

<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <a class="navbar-brand" href="#">Network Mode Switcher</a>
</nav>

<div class="container mt-5">
    <div class="card text-center">
        <div class="card-header">
            <h2>Current Mode: $MODE</h2>
        </div>
        <div class="card-body">
            <p class="card-text">Select the network mode you wish to activate:</p>
            <form action="switch_mode.sh" method="post">
                <button type="submit" name="mode" value="Switch to ProtonVPN" class="btn btn-primary btn-lg m-2">Switch to ProtonVPN</button>
                <button type="submit" name="mode" value="Switch to Tor" class="btn btn-secondary btn-lg m-2">Switch to Tor</button>
            </form>
        </div>
        <div class="card-footer text-muted">
            &copy; Your Company or Name
        </div>
    </div>
</div>

<!-- jQuery and Bootstrap JS -->
<script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.bundle.min.js"></script>
</body>
</html>
EOT