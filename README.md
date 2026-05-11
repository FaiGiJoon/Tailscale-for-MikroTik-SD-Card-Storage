# Tailscale for MikroTik Switch (SD Card Optimized)

This project provides a streamlined way to run Tailscale in a container on MikroTik switches, specifically optimized for devices with limited internal flash that use an SD card for storage.

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
    Upload `tailscale.tar` and `setup.rsc` to the `disk1` directory on your MikroTik.

### 3. Run the Setup Script

Connect to your MikroTik via WinBox Terminal or SSH and run:

```routeros
/import disk1/setup.rsc
```

*Note: You may want to edit `setup.rsc` first to set your `AUTH_KEY` and `lanSubnet`.*

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

## Management

Access the container shell:
```routeros
/container/shell [find where hostname="tailscale"]
```

Or SSH into the container:
```bash
ssh root@172.17.0.2
```
