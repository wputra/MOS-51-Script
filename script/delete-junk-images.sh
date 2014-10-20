#!/bin/sh

for i in $( cat image.txt ); do
#rbd -p images snap unprotect $i@snap
#rbd -p images snap purge $i
rbd -p images rm $i
done
