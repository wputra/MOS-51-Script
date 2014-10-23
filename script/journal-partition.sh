#!/bin/sh

lsblk > /root/nvme.txt
grep_output=`grep -e nvme.*10G /root/nvme.txt`
if [ "$grep_output" == "" ]; then
	sgdisk --load-backup=/root/patch/table /dev/nvme0n1
	sgdisk -G /dev/nvme0n1
fi