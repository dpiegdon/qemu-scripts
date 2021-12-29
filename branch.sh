#!/bin/bash
# vim: fdm=marker

. `dirname $0`/default_config.sh

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
	echo "$0 <destination>.qcow2 [baseimage]"
	exit 1
fi

if [ $# -eq 2 ]; then
	BASE="$2"
else
	BASE="$DEFAULT_BASE_IMAGE"
fi

DEST="${1}.qcow2"

if [[ "$DEST" = "$BASE" ]] || [[ "$DEST" = "$DEFAULT_BASE_IMAGE" ]]; then
	echo "You are trying to branch TO '$DEST',"
	echo "which would overwrite your base image."
	exit 1
fi

if [ ! -e "$BASE" ]; then
	echo "Base image '$BASE' doest not exist."
	exit 1
fi

if [ -e "$DEST" ]; then
	echo "destination '$DEST' already exists."
	exit 1
fi

qemu-img create -F qcow2 -f qcow2 -b $BASE $DEST

