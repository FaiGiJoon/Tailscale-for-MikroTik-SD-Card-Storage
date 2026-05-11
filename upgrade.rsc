# upgrade.rsc - MikroTik Tailscale Upgrade Script
#
# This script automates the process of upgrading the Tailscale container.
# It identifies the container by hostname, preserves its configuration,
# removes it, and then re-creates it using the latest image.

# --- Configuration ---
:local containerHostname "tailscale"
:local logPrefix "Tailscale-Upgrade"

# --- Helper Functions ---
:local logI do={
    :global logPrefix;
    :put ($logPrefix . ": " . $1);
    :log info ($logPrefix . ": " . $1);
}

# --- Main Script ---
/container
:local containerId [find where hostname=$containerHostname];

:if ([:len $containerId] = 0) do={
    $logI ("Error: Container with hostname '" . $containerHostname . "' not found.");
    :error "Aborting upgrade.";
}

:local rootDir [get $containerId root-dir];
:local dns [get $containerId dns];
:local logging [get $containerId logging];
:local envList [get $containerId envlist];
:local interface [get $containerId interface];
:local mounts [get $containerId mounts];
:local startOnBoot [get $containerId start-on-boot];
:local cmd [get $containerId cmd];
:local workDir [get $containerId workdir];

# Check if it was created from a remote image or a file
:local remoteImage [get $containerId remote-image];
:local file [get $containerId file];

$logI ("Upgrading container: " . $containerHostname);

# 1. Stop the container
$logI "Stopping the container...";
stop $containerId
:while ([get $containerId status] != "stopped") do={
    $logI "Waiting for container to stop...";
    :delay 5s;
}
$logI "Container stopped.";

# 2. Remove the container
$logI "Removing the container...";
remove $containerId
:delay 2s;
$logI "Container removed.";

# 3. Re-create the container
$logI "Re-creating the container...";
:if ([:len $remoteImage] > 0) do={
    # Re-create using remote image
    add remote-image=$remoteImage interface=$interface envlist=$envList \
        root-dir=$rootDir mounts=$mounts start-on-boot=$startOnBoot \
        hostname=$containerHostname dns=$dns logging=$logging cmd=$cmd workdir=$workDir
} else={
    # Re-create using file
    add file=$file interface=$interface envlist=$envList \
        root-dir=$rootDir mounts=$mounts start-on-boot=$startOnBoot \
        hostname=$containerHostname dns=$dns logging=$logging cmd=$cmd workdir=$workDir
}

# Wait for extraction/addition
:local newId "";
:while ([:len $newId] = 0) do={
    :set newId [find where hostname=$containerHostname];
    :if ([:len $newId] = 0) do={
        $logI "Waiting for container to be added...";
        :delay 5s;
    }
}

:while ([get $newId status] = "extracting") do={
    $logI "Waiting for extraction...";
    :delay 5s;
}

$logI "Container re-created.";

# 4. Start the container
$logI "Starting the container...";
start $newId
$logI "Upgrade process complete.";
