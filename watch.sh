#!/bin/sh
# vim: fdm=marker

. ./default_config.sh

remote-viewer -f spice://${SPICE_HOST}:${SPICE_PORT}/

