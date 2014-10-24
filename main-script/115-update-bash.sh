#!/bin/bash

##### update bash to against shellshock bug in all node
##### this bug actually have no effect to MOS environment, since no bash-based CGIs are used
##### but still, better safe than sorry
##### WARNING WARNING WARNING : NEVER, EVER, do "apt-get upgrade", since it will upgrade ALL packages

ALL=$( fuel node | grep -e ready | awk '//{print $1}' );
for i in $ALL; do
	rsync -avz ../script/sources.list node-$i:/etc/apt/
	ssh node-$i "apt-get update && apt-get --only-upgrade install bash"
done