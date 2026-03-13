#!/bin/bash
# vim: fdm=marker

. `dirname $0`/default_config.sh

if [ -n "$SUDO_USER" ] && [ -n "$SPICE_SOCKET" ]; then
	set -x
	sudo chown "$SUDO_USER" "$SPICE_SOCKET"
fi

remote-viewer -f --hotkeys=toggle-fullscreen=shift+f11 ${SPICE_URI} -f

