#!/bin/bash
# vim: fdm=marker

. ./default_config.sh

ssh -p $NET_SSH_TO_VM_PORT localhost $@

