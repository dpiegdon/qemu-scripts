#!/bin/bash
# list all PCI devices and their corresponding IOMMU group.
# copied from https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF
COLOR_BLUE="\033[1;34m"
COLOR_RESET="\033[m"

shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
	echo -e "${COLOR_BLUE}IOMMU Group ${g##*/}:${COLOR_RESET}"
	for d in $g/devices/*; do
		echo -e "\t$(lspci -nns ${d##*/})"
	done;
done;

