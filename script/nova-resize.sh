#!/bin/sh
su - nova -c 'pwd && echo "LogLevel=error" >> .ssh/config'
