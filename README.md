# Tailscale for MikroTik with MCP Support

This project provides a streamlined way to run Tailscale in a container on MikroTik routers and switches. It is optimized for devices with limited internal flash and includes an integrated **Model Context Protocol (MCP)** server to allow AI assistants to manage your router.

## Features

- **Tailscale Subnet Router**: Easily connect your MikroTik LAN to your Tailscale network.
- **SD Card Optimized**: Configured to store all container data on external storage (`disk1`) to save internal flash.
- **Integrated MCP Server**: Manage your MikroTik router using AI assistants like Claude Desktop or Cursor.
- **Automated Upgrade Script**: Simple `upgrade.rsc` script to update the Tailscale container from within RouterOS.
- **Persistent Storage**: Tailscale state is preserved across container updates and reboots.

## Prerequisites

- MikroTik RouterOS v7.6 or later.
- Device with Container support (ARM, ARM64, or x86).
- An SD card (formatted as `ext4` or `fat32` in RouterOS, typically `disk1`).
- Tailscale Auth Key (from the Tailscale admin console).

## Quick Start

### 1. Build the Image

On your local machine with Docker installed:

```bash
./build.sh linux/arm64  # Change to linux/arm or linux/amd64 if needed
```

This will produce `tailscale.tar`.

### 2. Prepare the MikroTik

1.  **Format the SD card** (if not already done):
    `/disk format-drive disk1 file-system=ext4`
2.  **Enable Container Mode**:
    `/system/device-mode/update container=yes`
    *Note: This requires a physical reboot and button press or power cycle.*
3.  **Upload Files**:
Upload `tailscale.tar`, `setup.rsc`, and `upgrade.rsc` to the `disk1` directory on your MikroTik.

### 3. Run the Setup Script

Connect to your MikroTik via WinBox Terminal or SSH and run:

```routeros
/import disk1/setup.rsc
```

*Note: You may want to edit `setup.rsc` first to set your `AUTH_KEY`, `lanSubnet`, and optionally MCP credentials.*

## Model Context Protocol (MCP) Integration

The container includes a built-in MCP server that allows AI assistants to interact with your MikroTik router.

### Tools Provided:
- `get_interfaces`: List network interfaces.
- `get_ip_addresses`: List IP addresses.
- `get_system_resource`: View CPU, memory, and uptime.
- `get_firewall_rules`: Inspect firewall/NAT rules.
- `run_command`: Execute arbitrary RouterOS API commands.

### Usage with Claude Desktop:
Add the following to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "mikrotik": {
      "command": "ssh",
      "args": ["-T", "root@<your-router-tailscale-ip>", "/opt/mcp-env/bin/python /usr/local/bin/mcp_server.py stdio"]
    }
  }
}
```

## Management & Upgrades

### Upgrading Tailscale
To upgrade the container to a new version:
1. Upload the new `tailscale.tar` to `disk1`.
2. Run the upgrade script:
```routeros
/import disk1/upgrade.rsc
```

### Accessing the Shell
Access the container shell:
```routeros
/container/shell [find where hostname="tailscale"]
```

Or SSH into the container:
```bash
ssh root@172.17.0.2
```

## Configuration Details

### SD Card Usage
This setup is configured to store:
- **Container Root FS**: `disk1/containers/tailscale`
- **Tailscale Config/State**: `disk1/tailscale/config` (mounted to `/var/lib/tailscale`)
- **Container Image**: `disk1/tailscale.tar`

This ensures that the internal flash (which is often very small on switches) is not consumed.

### Environment Variables

| Variable | Description |
| :--- | :--- |
| `AUTH_KEY` | Your Tailscale Auth Key. |
| `ADVERTISE_ROUTES` | Comma-separated routes to advertise (e.g., `192.168.88.0/24`). |
| `CONTAINER_GATEWAY` | The IP of the bridge interface on the MikroTik (e.g., `172.17.0.1`). |
| `PASSWORD` | Root password for SSH access to the container. |
| `ENABLE_MCP` | Set to `true` to enable the MCP server. |
| `MCP_USER` | RouterOS API username (default: `admin`). |
| `MCP_PASSWORD` | RouterOS API password. |

## Management

Access the container shell:
```routeros
/container/shell [find where hostname="tailscale"]
```

Or SSH into the container:
```bash
ssh root@172.17.0.2
```
