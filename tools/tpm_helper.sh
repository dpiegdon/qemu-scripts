#!/bin/sh

# to enable use of TPM:
#  - include $TPM_PARAMETERS in QEMU_EXTRA_OPTIONS,
#  - run tpm_start in pre_exec_hook
#  - run tpm_stop in post_exec_hook

tpm_start() {
	which swtpm || {
		echo "swtpm not found."
		exit -1
	}
	mkdir -p emulated_tpm
	swtpm socket --tpmstate dir=emulated_tpm --ctrl type=unixio,path=emulated_tpm.socket --log file=emulated_tpm/logfile,level=20,truncate --tpm2 &
	export SWTPM_PID="$!"
	sleep 0.2
}

tpm_stop() {
	sleep 0.2
	kill "$SWTPM_PID"
}

export TPM_PARAMETERS="-chardev socket,id=chrtpm,path=emulated_tpm.socket -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0"
