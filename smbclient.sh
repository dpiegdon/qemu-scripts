#!/bin/bash
# vim: fdm=marker

. `dirname $0`/default_config.sh

smbclient -p ${NET1_SMB_TO_VM_PORT} ${NET1_SMB_OPTS} //localhost/${NET1_SMB_SHARE}

