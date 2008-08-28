#!/bin/bash

# sed -n '/<key>CFBundleVersion<\/key>/{n;p;}' < Info.plist | awk -F '>' '{print $2}' | awk -F '<' '{print $1}'


if [ -d .git ] ; then
	# This version works in a git-svn environment
	SVN_REV=`git-svn log --oneline --limit 1 | cut -d ' ' -f 1`
elif [ -d .svn ] ; then
	# This works in pure svn
	SVN_REV="r`svn info | awk '/^Revision: [0-9]+$/ {print $2}'`"
else
	echo "Can't determine build number with svn or git."
	exit 1
fi

VERSION=`tail -n 1 VERSION`

echo "${VERSION}-${SVN_REV}"
