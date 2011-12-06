#!/bin/sh

# $Id$

function absolute_path()
{
    if [ ! -e $1 ]; then
	echo "'$1' does not exist"
	exit 1
    fi
    
    local pwd_=$(pwd)
    
    if [ -d "$1" ]; then
	cd "$1"
	pwd
    else
	local base_name=$(basename "$1")
	local path=$(dirname "$1")
	path=$(cd $path; pwd)
	if [ "$path" == "/" ]; then
	    echo "/$base_name" 
	else
	    echo "$path/$base_name" 
	fi
    fi

    cd ${pwd_}
}

if [ $# -eq 0 ]; then
    pwd
else
    for file in $*; do
	absolute_path $file
    done
fi

exit 0

