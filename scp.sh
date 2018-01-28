#!/bin/bash
# vim: fdm=marker

. `dirname $0`/default_config.sh

scp -p $NET_SSH_TO_VM_PORT localhost $@

