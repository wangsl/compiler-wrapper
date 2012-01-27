#!/bin/sh

# $Id$

#export BUILD_WRAPPER_SCRIPT=
#export SPECIAL_RULES_FUNCTION=

#export SOURCE_CODE_LIST_WITH_INTEL_COMPILERS=
#export SOURCE_CODE_LIST_WITH_GNU_COMPILERS=
#export REGULAR_EXPRESSION_LIST_FOR_SOURCE_CODE_WITH_INTEL_COMPILERS=
#export REGULAR_EXPRESSION_LIST_FOR_SOURCE_CODE_WITH_GNU_COMPILERS=
#export INVALID_FLAGS_FOR_INTEL_COMPILERS="-O2 -g"
#export INVALID_FLAGS_FOR_GNU_COMPILERS=
#export OPTIMIZATION_FLAGS=
#export OPTIMIZATION_FLAGS_FOR_INTEL_COMPILERS="-O3 -fPIC -unroll -ip -axP -xP -openmp -vec-report -par-report -openmp-report -Wno-deprecated -shared-intel -Wp64"
#export OPTIMIZATION_FLAGS_FOR_INTEL_FORTRAN_COMPILERS=
#export OPTIMIZATION_FLAGS_FOR_GNU_COMPILERS=
#export OPTIMIZATION_FLAGS_FOR_GNU_FORTRAN_COMPILERS=
#export INCLUDE_FLAGS=
#export INCLUDE_FLAGS_FOR_INTEL_COMPILERS=
#export INCLUDE_FLAGS_FOR_INTEL_FORTRAN_COMPILERS=
#export INCLUDE_FLAGS_FOR_GNU_COMPILERS=
#export INCLUDE_FLAGS_FOR_GNU_FORTRAN_COMPILERS=
#export LINK_FLAGS=
#export LINK_FLAGS_FOR_INTEL_COMPILERS="
#export LINK_FLAGS_FOR_GNU_COMPILERS="-fopenmp"
#export EXTRA_OBJECT_FILE_AND_LIBRARY_LIST=
#export STRING_MACROS=
#export FUNCTION_MACROS=
#export INTEL_MPI_BIN_PATH=
#export GNU_MPI_BIN_PATH=
#export DEFAULT_COMPILER="INTEL"
#export NO_ECHO_FLAGS=
#export REGULAR_EXPRESSIONS_FOR_NO_ECHO=
#export STRING_PREPEND_TO_ECHO=
#export DEBUG_LOG_FILE=tmp.log

#export CC=icc
#export CFLAGS="-O3 -fPIC -unroll -ip -axP -xP -openmp -vec-report -par-report -openmp-report -Wno-deprecated"
#export LDFLAGS="-shared-intel $CFLAGS"
#export LIBS=
#export CPPFLAGS=
#export CPP="icc -E"
#export CCAS=
#export CCASFLAGS=
#export CXX=icpc
#export CXXFLAGS=
#export CXXCPP="icpc -E"
#export F77=ifort
#export FFLAGS="$CFLAGS"

alias die='_error_exit_ "Error in file $0 at line $LINENO\n"'

function special_rules()
{
    return
    local arg=
    for arg in $*; do
	echo $arg
    done
}

function main() 
{
    source /etc/profile.d/env-modules.sh
    module purge
    module load intel/11.1.046

    local util=$HOME/bin/intel/util.sh
    if [ -e $util ]; then
	source $util
    fi
    
    export SPECIAL_RULES_FUNCTION=special_rules
    if [ "$SPECIAL_RULES_FUNCTION" != "" ]; then
	export BUILD_WRAPPER_SCRIPT=$(abspath.sh $0)
    fi

    export INTEL_BIN_PATH=$(dirname $(which icc))
    export GNU_BIN_PATH=$(dirname $(which gcc))

    export INVALID_FLAGS_FOR_GNU_COMPILERS="-O -O0 -O1 -O2 -g"
    export OPTIMIZATION_FLAGS_FOR_GNU_COMPILERS="-O3 -fPIC"

    export INVALID_FLAGS_FOR_INTEL_COMPILERS="-O -O0 -O1 -O2 -g -lm"
    export OPTIMIZATION_FLAGS_FOR_INTEL_COMPILERS="-O3 -fPIC -unroll -ip -axO -xO -openmp -vec-report -par-report -openmp-report -Wno-deprecated"
    export OPTIMIZATION_FLAGS_FOR_INTEL_FORTRAN_COMPILERS="-O3 -fPIC -unroll -ip -axO -xO -openmp -vec-report -par-report -openmp-report"

    export LINK_FLAGS_FOR_INTEL_COMPILERS="-shared-intel"

    if [ "$DEBUG_LOG_FILE" != "" ]; then
	rm -rf $DEBUG_LOG_FILE
    fi
    
    export LD_RUN_PATH=$LD_LIBRARY_PATH
    
    local args=$*
    local arg=
    for arg in $args; do
	
	case $arg in
	    
	    configure|conf)
		echo " Run configuration ..."
		./configure --build=x86_64-redhat-linux \
		    --prefix=/share/apps/flex/2.5.35/intel
		shift
		;;
	    
	    make)
		export PATH=.:$HOME/bin/intel:$PATH
		echo " Run make"
		eval "$args" 
		exit
		;;
	    
	    *)
		die " Usage: $0 <argument>: configure make"
		;;
	esac

	args=$(eval "echo $args | sed -e 's/$arg //'")
    done
}

## do the main work here
## do not modify the follwoing part, we just need to modify the main function

if [ "$TO_SOURCE_BUILD_WRAPPER_SCRIPT" == "" ]; then
    main "$*"
    exit
else
    unset -f main
fi

## do not add anything after this line