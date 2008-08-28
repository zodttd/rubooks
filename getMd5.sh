#!/bin/bash
#
# Calculate MD5 of file in first argument and print to stdout.
# This script attempts to use md5 on Mac or md5sum on Linux.

if [ -x /sbin/md5 ] ; then
	md5 -q $1
elif [ -x /usr/bin/md5sum ] ; then
	md5sum $1 | awk '{print $1}'
else
	echo "NoMd5BinaryFound"
	exit 1
fi
