#!/bin/bash
# usage: pasteFile.sh [-pub] filename
# 	
# Switches:
#	-pub  Make the post public.
#
# A script using post-file.in to paste a file to pastebin. Should make copying / sharing large files over SSH way easier. See http://post-file.it for more information on how it works.
#
# @todo allow for easier command posting using a pipe. 

PUB=false
for a in "$@"; do
	if [ "$a" = "-pub" ]; then
		PUB=true
	fi	
done

file=${BASH_ARGV[0]}

if [ ! -f $file ]; then
	echo "File does not exist."
	exit 1
fi

if $PUB ; then
	wget post-file.it/p --post-file $file
else
	wget post-file.it --post-file $file
fi

