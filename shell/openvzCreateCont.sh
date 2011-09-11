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

vzctl create ${cid} --ostemplate cd-debian-6.0-i386-minimal
vzctl set ${cid} --ipadd 10.11.12.${cid} --hostname $2 --nameserver 8.8.8.8 --searchdomain dec.im --diskspace ${4}G --vmguarpages ${3}M --oomguarpages ${3}M --privvmpages ${3}M:${3}M --save
vzctl start ${cid}
