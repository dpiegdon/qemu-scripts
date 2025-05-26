<!-- vim: fo+=a
-->

QEMU helper scripts
===================

This is a bunch of scripts that evolved over the time to run my virtual
machines in a standard way. Workflow is optimized for me personally, so you may
find a need for more or different options.

Specifically of value is the branching mechanism (which can easily be reduced
to just calling `qemu-img create` with the correct options, which I always
forget...


Workflow and Initial Setup
==========================

Prerequisites
-------------

Install `qemu-system-x86_64` and `remote-viewer` (part of `virt-viewer`).


Create configuration
--------------------

Copy `default_config.sh` to `config.sh`, edit anything you want to change and
strip everything else. Defaults will be loaded before loading your overrides.


Create a base disk
------------------

Initially you have to create a base filesystem image "base.img" from that you
start. You should be able to use any qemu-supported image format, but qcow2 is
a good choice. For example:

		qemu-img create -f qcow2 base.img 32G

Will create a 32GByte large image.


Create a branch
---------------

To use the created filesystem image, you have to create a branch from it. A
branch is a new image that uses the original one as backend, but anything newly
written to the disk will be stored into the new branch.

		./branch.sh installation

Later on, once you are done with a virtual machine and it is shut down, you can
either throw away the branch or commit it to the base image. Also you can have
branches of branches, thus multiple layers, if you feel like it. To commit a
branch do:

		qemu-img commit installation.qcow2


Run the virtual machine
-----------------------

Use the run.sh script to run your VM:

		./run.sh [detached] <branch-image> [optional options]

'detached' will cut any network-based connection to or from the VM.
'branch-image' is the image to use as primary hard drive. 'optional options'
are qemu options that should be passed to qemu for this run of the VM. E.g. to
newly install your debian system into the image, run:

		./run.sh installation.qcow2 -cdrom debian-netinstall.iso

Note that this does not open the VMs screen. See next section on how to do
this. What actually is opened is the VMs monitor console where you can control
the VM.


Watch the VM
------------

Starting a VM does not automatically open its screen. To open its screen, use
watch.sh , which in turn will run `remote-viewer`, a tool to use the SPICE
protocol to run the screen session over network. This can also be used to
stream a session over distant networks.

Note: Your VM guest will need to support QXL for this. See `man qemu` for more
information.


Drop or commit VM after use
---------------------------

Once installation is done, commit the branch and you have a nice, clean debian
install to do all kinds of destructive stuff inside. Always do your shenanigans
in a branch, so you can just throw them away afterwards.

Commit via:

		qemu-img commit <brach-image>

The branch-image automatically knows its immediate parent image and commits to
it.


Supplied tools
==============

`branch.sh` - Create a branch from the base image.

`config.sh` - Your configuration overrides for this VM.

`default_config.sh` - Default configurations.

`run.sh` - Run your VM.

`scp.sh` - If configured for SSH forwarding, run an SCP to the VM.

`smbclient.sh` - If configuration for SMB forwarding, open an smbclient session
to the VM.

`ssh.sh` - If configured for SSH forwarding, open an SSH session to the VM.

`watch.sh` - Show the VMs screen.

`tools/allow_pings.sh` - Tool to adjust kernel settings to be less restrictive
about ICMP ping packets. READ THE SCRIPT before using it! This will allow *any*
user to send pings.

`tools/cpuset_release_agent.sh` - Callback script that is executed by the
kernel when using exclusive CPU sets and a CPU set looses its last member
process. Currently this just deletes the cpuset.

`tools/iommu-mapping.sh` - List all PCI devices and their corresponding IOMMU
group.

`tools/net_if0_{down,up}.sh` - Example configuration scripts for setting up
qemu tap netdevs.

Best practices for branching workflow
=====================================

* The base image should only be the plain install of the used operating system,
  with a minimum set of additional tools.

* (If the VM is in active use) Once a week or so create a branch in that you
  run updates, then commit the branch.

* (If the VM is in active use and was updated regularly) Clean up the base
  image as described in the next section every few month or so.

* For each new thing that you want to try, create a branch. Afterwards drop the
  branch unless you may need it again on. Never commit experimental stuff,
  tools, configs et al into the base image.

* If you find a configuration that suits a specific task very well and will be
  used often, create a new copy of this repo and use the branch (merged with
  the current base image) as its new base image.


Cleaning up images and image sizes
----------------------------------

NOTE: this only works if
`EXTRA_DRIVE_MODE=",discard=unmap,detect-zeroes=unmap"`

The VirtIO disk allows the guest to discard areas (as usual with SSDs) and also
recognizes areas that are all zero. Both such areas get removed from qcow2-type
images and thus reduce the image size. Reduction may not show up in `ls -la`
until an image is fully rewritten.

It is a good idea to do this every few month.

Workflow for getting a *minimal size* image is:

* Get guest to a well-defined, good state that is a good new base for future
  runs. E.g. current run all software updates.

* In guest, clean up all files not required.

* In guest, run defragmentation (if available)

* In guest, overwrite all unused space with zeroes. (e.g. for linux: `cat
  /dev/zero > /removeme; rm /removeme`, or for windows: `sdelete64.exe -z C:`
  from the Sysinternal Suite)

* Shutdown guest.

* Create a new branch from this updated branch and boot it. Make sure new
  branch is working properly, then drop new branch again.

* Commit original branch to master. (e.g. `qemu-img commit recuded.qcow2`)

* Fully convert the base image to a new base image of format qcow2. e.g.:
  `qemu-img convert -O qcow2 base.img newbase.img`

* Replace the old with the new base.


Handling secure images
----------------------

If data of a branch must not be leaked, it is best to run this branch detached
(`detached` option to run.sh) and to have the branch-image in memory only. E.g.
disable swap on the hypervisor, checkout this repo in `/dev/shm/`, setup the
correct base image and create and run the branch. After shutting down the guest
when you are done, also shutdown the hypervisor. That will take care of the
remaining stuff in the hypervisor RAM.

Obsiously this may require A LOT of RAM. A not-so-secure method would be to
have the branch image on a real disk, but to wipe it afterwards. SSDs are very
nice for that as they are very fast, but data recovery might be easier. Instead
of wiping just the image, one could also wipe the whole disk. Or run the VM in
a crypto container and wipe the key material (e.g. LUKS header) afterwards.
Please do yourself a favour and do a proper threat assessment if this is
important to you!


Cheat Sheet
===========

Running Windows 10
------------------

The setup is specifically tuned to properly run Windows 10 in a VM. But a few
tweaks are needed after installing Windows 10 in the VM:

* Hardware Drivers

* QEMU guest agent

* SPICE Guest Tools

QXL, Watchdog, VirtIO Network, VirtIO Balloon Memory, VirtIO RNG, Virtio disk
and so on need special drivers. They should all be contained in:

* `https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe`

And newer versions may be found at:

* `https://gitlab.com/spice/spice-nsis`

If this is not enough, more may be found via:

* `https://www.spice-space.org/download.html` => Windows Guest Tools

* `https://fedoraproject.org/wiki/Windows_Virtio_Drivers`

* `https://wiki.gentoo.org/wiki/QEMU/Windows_guest`.

You will have to provide at least the virtio Disk drivers during installation,
e.g. via a floppy.

Once the system is installed you can insert the whole driver disk and install
all required drivers.

When you have the QXL drivers installed, you should get resolutions up to
2560x1600.


FIXME: provide more specific links and notes on what exactly to install. But to
do so I'd have to reinstall windows 10... meh.


Passing through PCI devices
---------------------------

If you want to pass a PCI device into the VM, you can do that if your computer
and the given PCI card support that. There are detailed HowTos on that topic on
the internet, e.g.:

- `https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF`

- `https://www.youtube.com/watch?v=3yhwJxWSqXI`

- `https://www.youtube.com/watch?v=4cBINJKX274`

So only a minimal description is provided here:

First, make sure the setup is supported in principle. Keywords: IOMMU in both
CPU and PCI card. Also see `tools/iommu-mapping.sh`.

Second, make sure no driver on linux attached to the device. You can check that
with `sudo lspci -nnk`.

Last, tell qemu to pass the device into the VM. E.g. by setting additional
config options to pass in devices `01:00.0` and `01:00.1`:

`-vga none -device vfio-pci,host=01:00.0 -device vfio-pci,host=01:00.1`


Attaching virtual USB sticks
----------------------------

Assuming `shared.img` is a qemu-compatible filesystem image:

create a shared partition file:

        dd if=/dev/zero bs=1024 of=shared.img count=$((1024*1024*2)) > shared.img

Setup and insert stick: In the monitor, run:

		drive_add 0 id=my_usb_disk,if=none,file=shared.img
		device_add usb-storage,id=my_usb_disk,drive=my_usb_disk

remove stick:

		device_del my_usb_disk

loopback: scan for partitions:

		losetup -P ...


Useful monitor command
----------------------

Generic status

* `info status`

VM state manipulation:

* `cont`
* `stop`
* `quit`
* `system_powerdown`
* `system_reset`
* `system_wakeup`

Snapshotting:

* `info snapshots`
* `savevm`
* `loadvm`
* `delvm`

