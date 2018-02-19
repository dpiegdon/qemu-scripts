#!/bin/bash -x
IFACE="$1"
ip address add 192.168.21.254/24 dev "${IFACE}"
ip address add 192.168.22.254/24 dev "${IFACE}"
ip address add 192.168.23.254/24 dev "${IFACE}"
ip link set dev "${IFACE}" up
