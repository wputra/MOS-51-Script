#!/bin/sh

ID=$( ceph osd tree | awk '/osd/{print $1};' );
for i in $ID; do
	service ceph -a stop osd.$i
done