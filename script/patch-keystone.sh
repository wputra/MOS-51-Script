#!/bin/sh
rsync -avz /root/patch/core.py /usr/share/pyshared/keystone/tests/
rsync -avz /root/patch/eventlet_server.py /usr/share/pyshared/keystone/common/environment/
rsync -avz /root/patch/config.py /usr/share/pyshared/keystone/common/
rsync -avz /root/patch/keystone-all /usr/bin/
