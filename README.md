# Apollo Supply

This repository initializes the "Download and VPN" layer of the Apollo media stack. It manages VPN connectivity and media acquisition services, designed to integrate with the Apollo Core swarm.

## Stack Overview

-   **Gluetun**: VPN client acting as a gateway for other services. Attached to the external `aether-net` overlay network.
-   **qBittorrent**: Torrent client, routed through Gluetun.
-   **SABnzbd**: Usenet client, routed through Gluetun.

## Networking

This stack is deployed as a **standalone Docker Compose** project (not Swarm mode) to support `network_mode: service:gluetun`.

-   **External Network**: `aether-net` (must exist in Swarm).
-   **VPN Routing**: Services use the Gluetun container's network stack.

## VPN Setup (AirVPN + WireGuard)

This stack is optimized for **AirVPN** using **WireGuard**. Follow these steps to configure your secrets:

1.  **Generate Config**:
    *   Log in to the [AirVPN Client Area](https://airvpn.org/client/).
    *   Go to **Config Generator**.
    *   Select **Linux** -> **WireGuard**.
    *   Choose your desired server location.
    *   Generate and download the configuration file (`.conf`).

2.  **Extract Secrets**:
    Open the `.conf` file and find the following values:
    *   `[Interface] PrivateKey` -> `WIREGUARD_PRIVATE_KEY`
    *   `[Interface] Address` (e.g., `10.x.x.x/32`) -> `WIREGUARD_ADDRESSES`
        > **Important:** If your config includes both IPv4 and IPv6 addresses (e.g., `10.x.x.x/32,fd7d:x:x:x:x/128`), **only use the IPv4 address**. Including the IPv6 address will cause startup errors if the host network does not support IPv6.
    *   `[Peer] PresharedKey` -> `WIREGUARD_PRESHARED_KEY`

3.  **Configure GitHub Secrets**:
    Add the following secrets to your repository:
    *   `VPN_SERVICE_PROVIDER`: `airvpn`
    *   `VPN_TYPE`: `wireguard`
    *   `WIREGUARD_PRIVATE_KEY`: *(Your Private Key)*
    *   `WIREGUARD_PRESHARED_KEY`: *(Your Preshared Key)*
    *   `WIREGUARD_ADDRESSES`: *(Your Address CIDR)*

4.  **Configure Port Forwarding (AirVPN)**:
    *   Log in to **AirVPN Client Area** -> **Ports**.
    *   Click **Add a new port**.
    *   Note the generated port number (e.g., `45678`).
    *   Update GitHub Secrets: Add `FIREWALL_VPN_INPUT_PORTS` with this number.
    *   In **qBittorrent** (Web UI -> Options -> Connection):
        *   Set **Port used for incoming connections** to this port.
        *   Uncheck **Use UPnP / NAT-PMP`.

5.  **Configure qBittorrent Interface (Recommended)**:
    *   In **qBittorrent** (Web UI -> Options -> Advanced):
    *   Set **Network Interface** to `tun0`.
    *   This ensures traffic binds explicitly to the VPN tunnel.

## Deployment

The stack is deployed via GitHub Actions on a self-hosted runner (`muspelheim`).

### Environment Variables

The following environment variables are passed to the container (handled via GitHub Secrets):

-   `VPN_SERVICE_PROVIDER`
-   `VPN_USER`
-   `VPN_PASSWORD`
-   `WIREGUARD_PRIVATE_KEY` (if using WireGuard)
-   `WIREGUARD_ADDRESSES` (if using WireGuard)

### Manual Deployment

```bash
./start.sh
```

Ensure environment variables are set if running manually without the repository secrets.

## Connecting to Prowlarr / Arr Stack

Since `qBittorrent` and `SABnzbd` are routed through the `gluetun` container, they share its IP address. When configuring download clients in Prowlarr, Sonarr, or Radarr (running in the `apollo-core` stack), use the following details:

*   **Hostname**: `gluetun` (Addressable via the `aether-net` overlay network)
*   **qBittorrent Port**: `8080`
*   **SABnzbd Port**: `8081`

### qBittorrent Default Password

On the first start, qBittorrent generates a temporary password printed in the container logs.

1.  **View Logs**:
    ```bash
    docker logs qbittorrent
    ```
    Look for a line containing `The temporary password is:`.

2.  **Change Password**:
    *   Log in to the Web UI at `http://<your-server-ip>:8080` using `admin` and the temporary password.
    *   Go to **Tools** -> **Options** -> **Web UI**.
    *   Under **Authentication**, change the username and password to your preference.
    *   (Optional) Disable CSRF protection if you encounter API issues with Prowlarr.

### SABnzbd Configuration

SABnzbd usually starts without a password by default, but follows a setup wizard on first access.

1.  **Access Wizard**:
    *   Go to `http://<your-server-ip>:8081`.
    *   Follow the **Quick Start Wizard**.

2.  **API Key**:
    *   Once configured, go to **Config** (gear icon) -> **General**.
    *   Copy the **API Key**. You will need this to connect Prowlarr, Sonarr, and Radarr.

3.  **Security (Optional but Recommended)**:
    *   In **Config** -> **General** -> **Security**, you can set a username and password if desired.

    *   Go to **Tools** -> **Options** -> **Web UI**.
    *   Under **Authentication**, change the username and password to your preference.
    *   (Optional) Disable CSRF protection if you encounter API issues with Prowlarr.

### Environment Variables

The following environment variables are passed to the container (handled via GitHub Secrets):

-   `VPN_SERVICE_PROVIDER`
-   `VPN_USER`
-   `VPN_PASSWORD`
-   `WIREGUARD_PRIVATE_KEY` (if using WireGuard)
-   `WIREGUARD_ADDRESSES` (if using WireGuard)

### Hostname Verification Fix (Required)

SABnzbd may reject requests with "Access denied - Hostname verification failed" by default. Since environment variable configuration is unreliable for existing setups, correct this with the following command on your server after deployment:

```bash
docker exec sabnzbd sed -i 's/^host_whitelist = .*/host_whitelist = sabnzbd, gluetun, muspelheim, */' /config/sabnzbd.ini && docker restart sabnzbd
```

This updates the `sabnzbd.ini` file to allow all hostnames.

## Troubleshooting

### Gluetun: "Context deadline exceeded" / Connection Loop
If Gluetun keeps restarting with `context deadline exceeded` or `i/o timeout` errors:
1.  **Check MTU**: This usually means packet fragmentation. Ensure `WIREGUARD_MTU=1280` is set in `docker-compose.yml`.
2.  **Disable Blocklists**: If the error persists specifically on blocklist updates, verify `BLOCK_MALICIOUS=off` is set.

### qBittorrent: Metadata Stalled / 0% Download
If torrents are stuck at "Downloading metadata" or 0%:
1.  **Check Interface**: In qBittorrent settings (Advanced), ensure **Network Interface** is set to `tun0`.
2.  **Port Forwarding**: Ensure you have forwarded a port in AirVPN and added it to `FIREWALL_VPN_INPUT_PORTS` (Gluetun) and qBittorrent's "Incoming Port" settings.
3.  **DNS**: Ensure Gluetun is using a valid DNS (e.g., `DNS_ADDRESS=1.1.1.1`).
