#!/bin/bash

##### intial preparation
##### store all needed file under /root directory

# define node role
ALL=$( fuel node | grep -e ready | awk '//{print $1}' );

# rsync patch & script folder to all node
for i in $ALL; do
	rsync -avz ../patch node-$i:/root/
	rsync -avz ../script node-$i:/root/
done