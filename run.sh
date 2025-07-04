#!/bin/bash
# vim: fdm=marker

. `dirname $0`/default_config.sh

COLOR_RED="\033[1;31m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[1;34m"
COLOR_RESET="\033[m"

# {{{ reset options in case user wants to run detached
if [ "$1" == "detached" ]; then
	# run a fully detached VM
	UUID=`uuidgen`
	NET1_SSH_TO_VM_PORT=
	NET1_SMB_TO_VM_PORT=
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
	OPT_SUDO_RUNAS="-run-with user=$SUDO_USER"
fi

if [[ "$SLOWDOWN" == "" ]]; then
	OPT_SLOWDOWN="-enable-kvm"
else
	OPT_SLOWDOWN="-icount $SLOWDOWN"
fi

if [[ "$MONITOR_VIA" == "" ]]; then
	OPT_MONITOR_VIA=""
else
	OPT_MONITOR_VIA="-monitor $MONITOR_VIA"
fi

if [[ "$QMP_VIA" == "" ]]; then
	OPT_QMP_VIA=""
else
	OPT_QMP_VIA="-qmp $QMP_VIA"
fi

if [[ "$DISPLAY_VIA" == "" ]]; then
	OPT_DISPLAY_VIA=""
else
	OPT_DISPLAY_VIA="-display $DISPLAY_VIA"
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

# {{{ make sure CPU is not vulnerable to anything that would the guest get priviliges or information
if grep 'SMT vulnerable' /sys/devices/system/cpu/vulnerabilities/l1tf; then
	if [ -z "$EXCLUSIVE_CPUSET" ]; then
		echo -e "${COLOR_RED}L1TF CPU bug present and SMT on, data leak possible. See CVE-2018-3646 and https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/l1tf.html for details.${COLOR_RESET}"
	else
		echo -e "${COLOR_YELLOW}L1TF CPU bug present and SMT on.${COLOR_RESET}"
		echo -e "${COLOR_YELLOW}Using exclusive CPUSET ${EXCLUSIVE_CPUSET} as extra mitigation.${COLOR_RESET}"
	fi
fi
# }}}

# {{{ setup exclusive CPU set, if required
if [ ! -z "$EXCLUSIVE_CPUSET" ]; then
	if [ -z "$OPT_SUDO" ]; then
		echo "Exclusive CPU sets only work if executed via sudo."
		exit -1
	fi

	set -e
	${OPT_SUDO} mkdir -p /sys/fs/cgroup/
	mount | grep cpuset || ${OPT_SUDO} mount -t cgroup -ocpuset cpuset /sys/fs/cgroup/cpuset

	MY_CPUSET="/sys/fs/cgroup/cpuset/qemu.$$"
	# FIXME https://www.kernel.org/doc/Documentation/cgroup-v1/cpusets.txt
	${OPT_SUDO} mkdir "$MY_CPUSET"
	echo "$(readlink -f ./tools/cpuset_release_agent.sh)" \
				| ${OPT_SUDO} tee "/sys/fs/cgroup/cpuset/release_agent"
	echo "1"		| ${OPT_SUDO} tee "$MY_CPUSET/notify_on_release"
	echo "1"		| ${OPT_SUDO} tee "$MY_CPUSET/cpuset.cpu_exclusive"
	echo "$EXCLUSIVE_CPUSET"| ${OPT_SUDO} tee "$MY_CPUSET/cpuset.cpus"
	cat /sys/fs/cgroup/cpuset/cpuset.mems \
				| ${OPT_SUDO} tee "$MY_CPUSET/cpuset.mems"
	echo "$$"		| ${OPT_SUDO} tee "$MY_CPUSET/tasks"
	set +e
fi
# }}}

pre_exec_hook

set -x

${NICE} ${OPT_SUDO} qemu-system-x86_64 \
	${OPT_SUDO_RUNAS} \
	${OPT_SLOWDOWN} \
	-spice ${OPT_SPICE} \
	${OPT_MONITOR_VIA} \
	${OPT_QMP_VIA} \
	${OPT_DISPLAY_VIA} \
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
	-vga ${VGA} \
	\
	-object rng-random,filename=/dev/urandom,id=rng0 \
	-device virtio-rng-pci,rng=rng0 \
	\
	-device i6300esb \
	-watchdog-action reset \
	\
	-device intel-hda -device hda-duplex \
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
	-chardev spicevmc,name=usbredir,id=usbredirchardev4 \
	-device usb-redir,chardev=usbredirchardev4,id=usbredirdev4 \
	-chardev spicevmc,name=usbredir,id=usbredirchardev5 \
	-device usb-redir,chardev=usbredirchardev5,id=usbredirdev5 \
	\
	$OPT_NET_FORWARD_SERIAL_PORT \
	\
	-boot order=cdn \
	\
	$QEMU_EXTRA_OPTIONS \
	\
	$@

post_exec_hook

