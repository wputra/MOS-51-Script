#!/bin/sh

# backup original ceph.conf
cp /etc/ceph/ceph.conf /etc/ceph/ceph.conf.bak

# modify ceph.conf so we can stop ceph osd from controller
ceph osd tree | awk '/host/{host=$4};/osd/{print "["$3"]\n" "host="host"\n";}' >> /etc/ceph/ceph.conf