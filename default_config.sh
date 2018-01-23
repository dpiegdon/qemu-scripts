#!/bin/sh

# default configuration
# override anything you like in ./config.sh

# VM identifier
UUID="123e4567-e89b-12d3-a456-426655440000"

# optionally run VM via sudo to gain privileges (e.g. for network configuration)
# and then drop privileges by changing to this user
SUDO_USER=""

# optionally run VM via this nice command
NICE="nice"

# configuration of spice remote control
SPICE_PORT="53504"
SPICE_HOST="127.0.0.1"
SPICE_EXTRA=",disable-ticketing"

# default base image for branching
DEFAULT_BASE_IMAGE="base.img"

# slowdown virtual machine: run instruction every 2^N cycles.
# if this is "" then KVM will be used.
SLOWDOWN=""

# amount of RAM for VM
MEM="2G"

# CPU type
CPU_TYPE="core2duo,nx,aes"

# CPU core count
CPU_CORES="2"

NET1_NETDEV=""
NET1_DEVICE=""
# e.g. for user-mode network (NAT VM behind hypervisor)
#NET1_NETDEV=user,id=unet0
#NET1_DEVICE=virtio-net,netdev=unet0
# or the same, but isolate guest:
#NET1_NETDEV=user,restrict=on,id=unet0
#NET1_DEVICE=virtio-net,netdev=unet0
# or for a plain network between hypervisor and guest,
# configured via two scripts net_if0_*.sh
#NET1_NETDEV=tap,id=net0,script=net_if0_up.sh,downscript=net_if0_down.sh
#NET1_DEVICE=e1000,netdev=net0

# optionally set a port for SSH forwarding to enable it
# (forwarding is applied to NET1 only and probably only
#  works in user-mode networks)
NET1_SSH_TO_VM_PORT=""
# host IP to listen to on the HYPERVISOR for SSH forwarding
NET1_SSH_HOST="127.0.0.1"

# optionally set a port for SMB forwarding to enable it
# (forwarding is applied to NET1 only and probably only
#  works in user-mode networks)
NET1_SMB_TO_VM_PORT=""
# host IP to listen to on the HYPERVISOR for SMB forwarding
NET1_SMB_HOST="127.0.0.1"
# extra options to pass to smbclient
NET1_SMB_OPTS="-U someuser"
# samba share to connect to on VM
NET1_SMB_SHARE="Users"

NET2_NETDEV=""
NET2_DEVICE=""

NET3_NETDEV=""
NET3_DEVICE=""

# three netdevs should be enough...

# optionally set a tcp port where the serial port will be available
NET_SERIAL_PORT=""

# any additional options that should always be passed to qemu
QEMU_EXTRA_OPTIONS=""


# -------------------------------------------------
# DO NOT COPY THIS to your configuration overrides.
# this actually loads your overrides.
[ -e config.sh ] && . ./config.sh
