#!/bin/sh
# release agent when a cgroup looses all processes.
# this one just deletes the cgroup, which is passed by the kernel as $1.
rmdir /sys/fs/cgroup/cpuset/$1
