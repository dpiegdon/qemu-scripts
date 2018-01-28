#!/bin/bash
# vim: fdm=marker

. `dirname $0`/default_config.sh

remote-viewer -f spice://${SPICE_HOST}:${SPICE_PORT}/

