#!/bin/bash
# Start the VM if not running
if ! virsh --connect qemu:///system domstate win11 | grep -q running; then
    virsh --connect qemu:///system start win11
    # Wait a moment for the VM to boot up
    sleep 2
fi
virt-viewer --connect qemu:///system --wait win11 