#!/bin/sh
ceph osd tree | awk '/host/{host=$4};/osd/{print "["$3"]\n" "host="host"\n";}'
