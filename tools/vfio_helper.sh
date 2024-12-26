#!/bin/sh

# to pull PCI device $PCIID into a VM:
#  - extend QEMU_EXTRA_OPTIONS with:	$(pci_generate_qemu_parameters $PCIID)
#  - extend pre_exec_hook with:		pci_rebind_vfio $PCIID
#  - extend post_exec_hook with:	pci_reset_and_rescan $PCIID
#
# where $PCIID can e.g. be found with
#   PCIID=$(lspci -Dnn | grep 'Cape Verde' | grep 'VGA compatible controller' | awk '{print $1}')
# or
#   PCIID=$(lspci -Dnn | grep '1106:3483' | awk '{print $1}')

# internal helper: unbind a single device from its current driver
pci_single_unbind() {
	DEVICE="$1"
	echo "unbinding PCI device ${DEVICE}"
	echo "$1" | sudo tee "/sys/bus/pci/devices/${DEVICE}/driver/unbind"
}

# internal helper: reset single device
pci_single_reset() {
	DEVICE="$1"
	echo "resetting PCI device ${DEVICE}"
	echo "1" | sudo tee "/sys/bus/pci/devices/${DEVICE}/remove"
}

# unbind all given devices and rebind them to the vfio driver
pci_rebind_vfio() {
	DEVICES="$@"
	sudo rmmod vfio-pci
	for DEV in ${DEVICES}; do
		pci_single_unbind ${DEV}
	done
	sleep 0.5
	sudo modprobe vfio-pci
	sleep 0.5
}

# reset all given devices from vfio and force pci rescan
pci_reset_and_rescan() {
	DEVICES="$@"
	if [ ! -z "${DEVICES}" ]; then
		for DEV in ${DEVICES}; do
			pci_single_reset ${DEV}
		done;
		sleep 1
		echo "1" | sudo tee /sys/bus/pci/rescan
	fi
}

# generate a list of QEMU parameters to use given pci devices
pci_generate_qemu_parameters() {
	DEVICES="$@"
	PARAMS=""
	for DEV in ${DEVICES}; do
		PARAMS="${PARAMS} -device vfio-pci,host=${DEV}"
	done;
	echo $PARAMS
}
