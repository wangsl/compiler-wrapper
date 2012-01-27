#!/bin/sh

# $Id$

function prepend_to_env_variable()
{
    local env_variable=$1
    local new_arguments=$2
    local seperate_field=" "
    if [[ $# -eq 3 ]]; then
	local seperate_field=$3
    fi
    local cmd="export $env_variable=\"${new_arguments}${seperate_field}\$${env_variable}${seperate_field}\""
    eval "$cmd"
    return
}

function append_to_env_variable()
{
    local env_variable=$1
    local new_arguments=$2
    local seperate_field=" "
    if [[ $# -eq 3 ]]; then
	local seperate_field=$3
    fi
    local cmd="export $env_variable=\"\$${env_variable}${seperate_field}${seperate_field}${new_arguments}\""
    eval "$cmd"
    return
}

function LD_LIBRARY_PATH_to_rpath()
{
    local ld_lib_paths=$(echo $LD_LIBRARY_PATH | sed -e "s/:/\n/g" | sort -u)
    
    local lib_path=
    for lib_path in $ld_lib_paths; do
	if [ "$lib_path" != "." ]; then
	    if [ -d $lib_path ]; then
		echo -n "-Wl,-rpath=$lib_path "
	    fi
	fi
    done
    echo
}

function cecho()
{
    local black='\E[30;47m'
    local red='\E[31;47m'
    local green='\E[32;47m'
    local yellow='\E[33;47m'
    local blue='\E[34;47m'
    local magenta='\E[35;47m'
    local cyan='\E[36;47m'
    local white='\E[37;47m'
    
    local color=$1
    local message="$2"
    
    local command="echo -en \$$color\$message"
    eval $command
    tput sgr0
    echo
}

function _error_exit_()
{
    cecho "red" "$*"
    echo
    exit 1
}

function _warn_()
{
    cecho "cyan" "$*"
    echo
}

function sort_and_uniq()
{
    if [ "$*" != "" ]; then 
	echo "$*" | sed -e 's/ /\n/g' | sort -u
    fi
}
