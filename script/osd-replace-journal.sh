#!/bin/sh

ID=$( cat part.txt );
x=4;

for i in $ID; do
	ls -al && stop ceph-osd id=$i && ceph-osd -i $i --flush-journal
			rm -f /var/lib/ceph/osd/ceph-$i/journal && ln -s /dev/nvme0n1p$x /var/lib/ceph/osd/ceph-$i/journal && ls -al
			x=$((x + 1))
	ceph-osd -i $i --mkjournal && start ceph-osd id=$i
done