#!/bin/bash
# vim: fdm=marker

. `dirname $0`/default_config.sh

remote-viewer -f --hotkeys=toggle-fullscreen=shift+f11 spice://${SPICE_HOST}:${SPICE_PORT}/ -f

