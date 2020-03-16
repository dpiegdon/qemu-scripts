#!/bin/sh +x
# this command would allow the guest to send out pings,
# even if it is running as a normal user.
# NOTA BENE: RTFM. this actually allows ANY user on the hypervisor to
#            send out pings, until the next reboot.
sysctl -w net.ipv4.ping_group_range='0 2147483647'
