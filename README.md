raspberry-pi-vpn-tor-ap/
├── README.md
├── .gitignore
├── setup_network.sh
├── scripts/
│   ├── switch_to_vpn.sh
│   └── switch_to_tor.sh
├── web_interface/
│   ├── index.sh
│   ├── switch_mode.sh
│   ├── setup.sh
│   └── style.css

# Raspberry Pi VPN/Tor Wireless Access Point

This project turns your Raspberry Pi into a wireless access point that routes traffic through either a VPN (ProtonVPN) or the Tor network. Users can connect to the Pi's Wi-Fi and have their internet traffic securely routed, with the ability for the admin to switch between VPN and Tor modes via a web interface.

## **Features**

- **Wireless Access Point:** The Raspberry Pi serves as a Wi-Fi hotspot.
- **VPN Support:** Traffic is routed through ProtonVPN using the ProtonVPN CLI.
- **Tor Support:** Option to route traffic through the Tor network for anonymity.
- **Web Interface:**
  - **Admin Panel:** Switch between VPN and Tor modes.
  - **Initial Setup Page:** Enter your desired SSID and passphrase through a modern web interface with animations.
- **Easy Setup:** Automated installation script to set up everything.

---

## **Prerequisites**

- **Hardware:**
  - Raspberry Pi (3, 4, or later with built-in Wi-Fi or a compatible USB Wi-Fi adapter)
  - Ethernet cable (to connect the Pi to your main router)
  - Optional: Alfa USB Wi-Fi adapter for improved Wi-Fi performance

- **Software:**
  - Raspberry Pi OS (Latest version)

- **Accounts:**
  - ProtonVPN account (Basic plan or higher recommended)

---

## **Installation**

### **1. Clone the Repository**

```bash
git clone https://github.com/yourusername/raspberry-pi-vpn-tor-ap.git
cd raspberry-pi-vpn-tor-ap
```

