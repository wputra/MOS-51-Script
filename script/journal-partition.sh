#!/bin/sh

CEPH=$( fuel node | grep -e ceph | awk '//{print $1}' );
for i in $CEPH; do
	lsblk > part.txt
	grep_output=`grep -e nvme.*10G part.txt`
		if [ "$grep_output" == "" ]; then
			sgdisk --load-backup=/root/patch/table /dev/nvme0n1
			sgdisk -G /dev/nvme0n1
		fi
done