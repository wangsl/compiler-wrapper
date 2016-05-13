#!/bin/bash

# $Id: build-nyu.sh 38 2013-06-19 19:12:11Z wangsl2001@gmail.com $

#export BUILD_WRAPPER_SCRIPT=
#export SPECIAL_RULES_FUNCTION=

#export SOURCE_CODE_LIST_WITH_INTEL_COMPILERS=
#export SOURCE_CODE_LIST_WITH_GNU_COMPILERS=
#export REGULAR_EXPRESSION_LIST_FOR_SOURCE_CODE_WITH_INTEL_COMPILERS=
#export REGULAR_EXPRESSION_LIST_FOR_SOURCE_CODE_WITH_GNU_COMPILERS=
#export INVALID_FLAGS_FOR_INTEL_COMPILERS=
#export INVALID_FLAGS_FOR_GNU_COMPILERS=
#export OPTIMIZATION_FLAGS=
#export OPTIMIZATION_FLAGS_FOR_INTEL_COMPILERS=
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
#export CFLAGS=
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
        if [ "$arg" == "build/temp.linux-x86_64-2.7/src/_png.o" ]; then
	    append_to_env_variable INVALID_FLAGS_FOR_GNU_COMPILERS "-I/share/apps/intel/14.0.2/composer_xe_2013_sp1.2.144/mkl/include  -I/share/apps/intel/14.0.2/include"
	    export DEFAULT_COMPILER="GNU"
	    return
	fi
    done
}

function main() 
{
    module purge
    export LD_LIBRARY_PATH=
    module load python/intel/2.7.6

    export MY_INTEL_PATH=$HOME/bin/intel
    
    local util=$MY_INTEL_PATH/util.sh
    if [ -e $util ]; then
	source $util
    fi
    
    export SPECIAL_RULES_FUNCTION=special_rules
    if [ "$SPECIAL_RULES_FUNCTION" != "" ]; then
	export BUILD_WRAPPER_SCRIPT=$(abspath.sh $0)
    fi
    
    export INTEL_BIN_PATH=$(dirname $(which icc))
    export GNU_BIN_PATH=$(dirname $(which gcc))
    #export INTEL_MPI_BIN_PATH=$(dirname $(which mpicc))
    
    export INVALID_FLAGS_FOR_GNU_COMPILERS="-O -O0 -O1 -O2 -g -g0"
    export OPTIMIZATION_FLAGS_FOR_GNU_COMPILERS="-O3 -fPIC -fopenmp -msse4.2"
    
    export INVALID_FLAGS_FOR_INTEL_COMPILERS="-O -O0 -O1 -O2 -g -g0 -lm -fwrapv -OPT:Olimit=0 -I/share/apps/python/2.7.6/intel/include"
    export OPTIMIZATION_FLAGS_FOR_INTEL_COMPILERS="-O3 -fPIC -unroll -ip -axavx -xsse4.2 -openmp -vec-report -par-report -openmp-report -Wno-deprecated"
    export OPTIMIZATION_FLAGS_FOR_INTEL_FORTRAN_COMPILERS="-O3 -fPIC -unroll -ip -axavx -xsse4.2 -openmp -vec-report -par-report -openmp-report"
    
    export CPPFLAGS=$(for inc in $(env | grep _INC= | cut -d= -f2); do echo '-I'$inc; done | xargs)
    export LDFLAGS=$(for lib in $(env | grep _LIB= | cut -d= -f2); do echo '-L'$lib; done | xargs)
    
    prepend_to_env_variable INCLUDE_FLAGS "$CPPFLAGS"
    prepend_to_env_variable LINK_FLAGS "$LDFLAGS"

    export LINK_FLAGS_FOR_INTEL_COMPILERS="-shared-intel"
    export EXTRA_LINK_FLAGS="$(LD_LIBRARY_PATH_to_rpath)"

    prepend_to_env_variable EXTRA_LINK_FLAGS "-L$PYTHON_LIB -lpython2.7"

    if [ "$DEBUG_LOG_FILE" != "" ]; then
	rm -rf $DEBUG_LOG_FILE
    fi
    
    export LD_RUN_PATH=$LD_LIBRARY_PATH

    local prefix=
    if [ "$USER" == "wang" ]; then
	prefix=$(readlink -e ../local)
	#prefix=/share/apps/cutadapt/1.8.1/intel
	export PYTHONPATH=$prefix/lib/python2.7/site-packages:$PYTHONPATH
	mkdir -p $prefix/lib/python2.7/site-packages
	prefix="--prefix=$prefix"
    fi
    
    local args=$*
    local arg=
    for arg in $args; do
	
	case $arg in
	    
	    configure|conf)
		echo " Run configuration ..."
		export PATH=.:$MY_INTEL_PATH:$PATH
		if [ -e configure.py ]; then
		    python configure.py
		else
		    python setup.py build
		fi
		;;
	    
	    install)
		export PATH=.:$MY_INTEL_PATH:$PATH
		echo " Run install"
		python setup.py install $prefix
		;;

	    pip)
		export PATH=.:$MY_INTEL_PATH:$PATH
		export PYTHONUSERBASE=/home/wang/spacy-20151113/tmp 
		pip install --user --verbose --no-cache-dir spacy
		exit
		;;
	    
	    test)
		echo " Run test"
		python setup.py test
		;;
	    
	    cmake)
		module load cmake/intel/2.8.8
		export PATH=.:$MY_INTEL_PATH:$PATH
		
                export CC=icc
                export CXX=icpc
		cmake \
		    -DCMAKE_BUILD_TYPE=release \
		    -DCMAKE_INSTALL_PREFIX:PATH=$prefix \
		    ../breakdancer
                ;;
	    
	    make)
		export PATH=.:$MY_INTEL_PATH:$PATH
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
