#!/bin/bash
# vim: fdm=marker

. `dirname $0`/default_config.sh

# {{{ reset options in case user wants to run detached
if [ "$1" == "detached" ]; then
	# run a fully detached VM
	UUID=`uuidgen`
	NET_SSH_TO_VM_PORT=
	NET_SMB_TO_VM_PORT=
	NET_SERIAL_PORT=
	NET1_NETDEV=""
	NET1_DEVICE=""
	NET2_NETDEV=""
	NET2_DEVICE=""
	NET3_NETDEV=""
	NET3_DEVICE=""
fi
# }}}

# {{{ print help if user forgot parameters
if [ $# -lt 1 ]; then
	echo "$0 runs a qemu virtual machine image"
	echo "parameters:"
	echo ""
	echo "    $0 [detached] <image-file> [...]"
	echo ""
	echo "    detached:   fully detach VM from network and remove any forwardings"
	echo "    image-file: image file to use as primary hard drive"
	echo "    [...]:      further optional arguments directly passed to QEMU."
	exit 1
fi
# }}}

# access to smb dir via \\10.0.2.4\qemu
IMAGE="$1"
shift

# {{{ deny to directly run base image
if [[ "$IMAGE" == "$DEFAULT_BASE_IMAGE" ]]; then
	echo "please don't run the base image."
	echo "if you want to change the base image,"
	echo "run in a branch and then commit a branch."
	echo "That way you are always sure of what you are committing"
	exit 1
fi
# }}}

# {{{ evaluate config parameters
OPT_SPICE="port=${SPICE_PORT},addr=${SPICE_HOST}${SPICE_EXTRA}"

if [[ "$SUDO_USER" == "" ]]; then
	OPT_SUDO=""
	OPT_SUDO_RUNAS=""
else
	OPT_SUDO="sudo"
	OPT_SUDO_RUNAS="-runas $SUDO_USER"
fi

if [[ "$SLOWDOWN" == "" ]]; then
	OPT_SLOWDOWN="-enable-kvm"
else
	OPT_SLOWDOWN="-icount $SLOWDOWN"
fi
if [[ -z $NET1_NETDEV ]]; then
	OPT_NET1_NETDEV=""
	OPT_NET1_DEVICE=""
else
	OPT_NET1_NETDEV="-netdev ${NET1_NETDEV}"
	OPT_NET1_DEVICE="-device ${NET1_DEVICE}"
fi

if [[ $NET1_SSH_TO_VM_PORT != "" ]]; then
	OPT_NET1_FORWARD_SSH=",hostfwd=tcp:${NET1_SSH_HOST}:${NET1_SSH_TO_VM_PORT}-10.0.2.15:22"
else
	OPT_NET1_FORWARD_SSH=""
fi

if [[ $NET1_SMB_TO_VM_PORT != "" ]]; then
	OPT_NET1_FORWARD_SMB=",hostfwd=tcp:${NET1_SMB_HOST}:${NET1_SMB_TO_VM_PORT}-10.0.2.15:445"
else
	OPT_NET1_FORWARD_SMB=""
fi

if [[ -z $NET2_NETDEV ]]; then
	OPT_NET2_NETDEV=""
	OPT_NET2_DEVICE=""
else
	OPT_NET2_NETDEV="-netdev ${NET2_NETDEV}"
	OPT_NET2_DEVICE="-device ${NET2_DEVICE}"
fi

if [[ -z $NET3_NETDEV ]]; then
	OPT_NET3_NETDEV=""
	OPT_NET3_DEVICE=""
else
	OPT_NET3_NETDEV="-netdev ${NET3_NETDEV}"
	OPT_NET3_DEVICE="-device ${NET3_DEVICE}"
fi

if [[ -z $NET_SERIAL_PORT ]]; then
	OPT_NET_FORWARD_SERIAL_PORT=""
else
	OPT_NET_FORWARD_SERIAL_PORT="-serial tcp::$NET_SERIAL_PORT,server"
fi

case $USB_VERSION in
	2)
		USB_DEVICES="	-device ich9-usb-ehci1,id=usb \
				-device ich9-usb-uhci1,masterbus=usb.0,firstport=0,multifunction=on \
				-device ich9-usb-uhci2,masterbus=usb.0,firstport=2 \
				-device ich9-usb-uhci3,masterbus=usb.0,firstport=4 \
				"
		;;
	3)
		USB_DEVICES="-device nec-usb-xhci,id=usb"
		;;
	*)
		echo "invalid USB version selected. pick one of '2' or '3'."
		exit -1;
		;;
esac;

# }}}

set -x

${NICE} ${OPT_SUDO} qemu-system-x86_64 \
	${OPT_SUDO_RUNAS} \
	${OPT_SLOWDOWN} \
	-spice ${OPT_SPICE} \
	-display none \
	-monitor stdio \
	\
	-uuid ${UUID} \
	\
	-cpu ${CPU_TYPE} -smp cores=${CPU_CORES} \
	\
	-m ${MEM} \
	-device virtio-balloon \
	\
	-drive "file=${IMAGE}${DEFAULT_DRIVE_MODE}${EXTRA_DRIVE_MODE}" \
	\
	-vga qxl \
	\
	-object rng-random,filename=/dev/urandom,id=rng0 \
	-device virtio-rng-pci,rng=rng0 \
	\
	-watchdog i6300esb \
	-watchdog-action reset \
	\
	-soundhw hda \
	\
	${OPT_NET1_NETDEV}${OPT_NET1_FORWARD_SSH}${OPT_NET1_FORWARD_SMB} ${OPT_NET1_DEVICE} \
	${OPT_NET2_NETDEV} ${OPT_NET2_DEVICE} \
	${OPT_NET3_NETDEV} ${OPT_NET3_DEVICE} \
	\
	-usb \
	-device usb-tablet \
	${USB_DEVICES} \
	-chardev spicevmc,name=usbredir,id=usbredirchardev1 \
	-device usb-redir,chardev=usbredirchardev1,id=usbredirdev1 \
	-chardev spicevmc,name=usbredir,id=usbredirchardev2 \
	-device usb-redir,chardev=usbredirchardev2,id=usbredirdev2 \
	-chardev spicevmc,name=usbredir,id=usbredirchardev3 \
	-device usb-redir,chardev=usbredirchardev3,id=usbredirdev3 \
	\
	$OPT_NET_FORWARD_SERIAL_PORT \
	\
	-boot order=cdn \
	\
	$QEMU_EXTRA_OPTIONS \
	\
	$@

