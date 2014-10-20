#!/bin/sh
cp /etc/ceph/ceph.conf /etc/ceph/ceph.conf.bak
ceph osd tree | awk '/host/{host=$4};/osd/{print "["$3"]\n" "host="host"\n";}' >> /etc/ceph/ceph.conf