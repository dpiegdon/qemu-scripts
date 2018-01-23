#!/bin/sh
# vim: fdm=marker

. ./default_config.sh

smbclient -p $NET_SMB_TO_VM_PORT $NET_SMB_OPTS //localhost/$NET_SMB_SHARE

