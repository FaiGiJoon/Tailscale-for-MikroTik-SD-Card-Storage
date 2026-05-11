import os
import json
import logging
import routeros_api
from mcp.server.fastmcp import FastMCP

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mikrotik-mcp")

# Initialize FastMCP
mcp = FastMCP("MikroTik RouterOS")

# Configuration from environment variables
HOST = os.environ.get("CONTAINER_GATEWAY", "172.17.0.1")
USERNAME = os.environ.get("MCP_USER", "admin")
PASSWORD = os.environ.get("MCP_PASSWORD", "")
PORT = int(os.environ.get("MCP_PORT", 8728))

def get_api():
    connection = routeros_api.RouterOsApiPool(
        HOST,
        username=USERNAME,
        password=PASSWORD,
        port=PORT,
        plaintext_login=True
    )
    return connection

@mcp.tool()
def run_command(path: str, command: str = "get", **kwargs):
    """
    Execute a command on a specific RouterOS resource path.
    Example: path='/ip/address', command='get'
    """
    try:
        connection = get_api()
        api = connection.get_api()
        resource = api.get_resource(path)

        method = getattr(resource, command)
        result = method(**kwargs)

        connection.disconnect()
        return json.dumps(result, indent=2)
    except Exception as e:
        return f"Error executing command: {str(e)}"

@mcp.tool()
def get_interfaces():
    """Get a list of all network interfaces."""
    return run_command("/interface")

@mcp.tool()
def get_ip_addresses():
    """Get a list of all IP addresses configured on the router."""
    return run_command("/ip/address")

@mcp.tool()
def get_system_resource():
    """Get system resource information (CPU, memory, uptime, etc.)"""
    return run_command("/system/resource")

@mcp.tool()
def get_firewall_rules(table: str = "filter"):
    """
    Get firewall rules.
    table: 'filter', 'nat', or 'mangle'
    """
    return run_command(f"/ip/firewall/{table}")

@mcp.tool()
def add_ip_address(address: str, interface: str):
    """Add a new IP address to an interface."""
    return run_command("/ip/address", command="add", address=address, interface=interface)

if __name__ == "__main__":
    mcp.run()
