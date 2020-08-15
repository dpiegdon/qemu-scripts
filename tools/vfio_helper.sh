#!/bin/sh

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
