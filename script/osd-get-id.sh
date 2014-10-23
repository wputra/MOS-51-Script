#!/bin/sh

# get osd id in this node and print to file
df -h | grep osd | awk '{ print substr( $0, 62 ) }' > /root/part.txt