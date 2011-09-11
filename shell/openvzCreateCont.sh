#!/bin/bash

#vzcreate 100 le.hostname.tld 64 10

cid=$1

if [ $# -lt 4 ]; then
	echo "I keel you, nub."
	echo "(Syntax: $0 <ctid> <hostname> <ram MB> <disk GB>)"
	exit 1
fi
if [ -e /vz/private/${cid} ]; then
	echo "I keel you, nub."
	echo "(Container exists)"
	exit 1
fi
