#!/bin/sh

INFILE="$1"
OUTFILE="$2"
[ -e "$INFILE" ] || {
	echo "input file does not exists: $INFILE"
	exit 1
}
[ -e "$OUTFILE" ] && {
	echo "output file already exists: $OUTFILE"
	exit 1
}

qemu-img convert \
	-p \
	-f qcow2 -O qcow2 \
	-c -o compression_type=zstd \
	"$INFILE" \
	"$OUTFILE"
