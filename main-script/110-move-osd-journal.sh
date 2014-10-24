#!/bin/bash

##### since in MOS 5.1 doesnt know about nvme device
##### we must move journal from sd device to nvme device

# set noout so ceph not rebalancing data while maintenence

ssh node-1 "ceph osd set noout"

# after make sure nvme device already partitioned properly,
# we can start to move journal

CEPH=$( fuel node | grep -e ceph | awk '//{print $1}' );
for i in $CEPH; do
	ssh node-$i "bash /root/script/journal-partition.sh"
	ssh node-$i "bash /root/script/osd-get-id.sh"
	ssh node-$i "bash /root/script/osd-replace-journal.sh"
done

# unset noout and make sure ceph cluster in health state

ssh node-1 "ceph osd unset noout"