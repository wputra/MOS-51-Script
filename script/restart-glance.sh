#!/bin/sh

for i in $( initctl list | grep running | grep -e glance | awk '//{print $1}' ); do
service $i restart
done
