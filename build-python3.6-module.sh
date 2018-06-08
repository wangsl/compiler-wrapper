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

#grep "module load" build-caffe.sh | grep -v "#grep" | awk '{printf "%s(\"%s\")\n", $2, $3}'

#set -e

alias die='_error_exit_ "Error in file $0 at line $LINENO\n"'


function special_rules()
{
    local arg=
    for arg in $*; do
	echo "$arg"
    done
}

function main() 
{
    export LMOD_DISABLE_SAME_NAME_AUTOSWAP=yes
    module use /share/apps/modulefiles
    module purge
    export LD_LIBRARY_PATH=
    module load python3/intel/3.6.3
    
    export MY_INTEL_PATH=/home/wang/bin/intel
    
    local util=$MY_INTEL_PATH/util.sh
    if [ -e $util ]; then
	source $util
    fi
    
    export SPECIAL_RULES_FUNCTION=special_rules
    if [ "$SPECIAL_RULES_FUNCTION" != "" ]; then
	export BUILD_WRAPPER_SCRIPT=$(readlink -e $0)
    fi
    
    export GNU_BIN_PATH=$(dirname $(which gcc))
    export INTEL_BIN_PATH=$(dirname $(which icc))
    #export INTEL_MPI_BIN_PATH=$(dirname $(which mpicc))
    
    export INVALID_FLAGS_FOR_GNU_COMPILERS="-O -O0 -O1 -O2 -O3 -g -g0 -fp-model strict -Olimit 1500 -I$INTEL_INC -I$MKL_INC"
    export OPTIMIZATION_FLAGS_FOR_GNU_COMPILERS="-fPIC -fopenmp -mavx -mno-avx2"
    
    export INVALID_FLAGS_FOR_INTEL_COMPILERS="-O -O0 -O1 -O2 -O3 -g -g0 -lm -xhost -fast -Olimit 1500"

    export OPTIMIZATION_FLAGS_FOR_INTEL_COMPILERS="-fPIC -unroll -ip -axCORE-AVX2 -qopenmp -qopt-report-stdout -qopt-report-phase=openmp"
    
    export OPTIMIZATION_FLAGS_FOR_INTEL_FORTRAN_COMPILERS="-fPIC -unroll -ip -axCORE-AVX2 -qopenmp -qopt-report-phase=openmp"
    
    export OPTIMIZATION_FLAGS="-O3"
    
    export CPPFLAGS=$(for inc in $(env -u INTEL_INC -u MKL_INC | grep _INC= | cut -d= -f2); do echo '-I'$inc; done | xargs)
    export LDFLAGS=$(for lib in $(env | grep _LIB= | cut -d= -f2); do echo '-L'$lib; done | xargs)
    
    prepend_to_env_variable INCLUDE_FLAGS "$CPPFLAGS"
    prepend_to_env_variable LINK_FLAGS "$LDFLAGS"

    prepend_to_env_variable INTEL_INCLUDE_FLAGS "-I$INTEL_INC -I$MKL_INC"
    
    export LINK_FLAGS_FOR_INTEL_COMPILERS="-shared-intel"
    export EXTRA_LINK_FLAGS="$(LD_LIBRARY_PATH_to_rpath)"

    prepend_to_env_variable EXTRA_LINK_FLAGS "-L$PYTHON3_LIB -lpython3"
    
    if [ "$DEBUG_LOG_FILE" != "" ]; then
	rm -rf $DEBUG_LOG_FILE
    fi
    
    export LD_RUN_PATH=$LD_LIBRARY_PATH
    
    local prefix= 
    if [ "$USER" == "wang" ]; then
        prefix=$(readlink -e ../local)
	#prefix=/share/apps/gensim/1.0.1/intel/python3.5
	export PYTHONPATH=$prefix/lib/python3.6/site-packages:$PYTHONPATH
        mkdir -p $prefix/lib/python3.6/site-packages
        prefix="--prefix=$prefix"
    fi

    #export N_MAKE_THREADS=60

    #export DEFAULT_COMPILER="GNU"

    local args=$*
    local arg=
    for arg in $args; do
	
	case $arg in
	    
	    configure|conf)
                echo " Run configuration ..."
                export PATH=.:$MY_INTEL_PATH:$PATH
                python3 setup.py build 
                ;;
	    
            install)
                echo " Run install"
		export PATH=.:$MY_INTEL_PATH:$PATH
                python3 setup.py install $prefix
                ;;

	    pip)
                export PATH=.:$MY_INTEL_PATH:$PATH
                export PYTHONUSERBASE=/home/wang/spacy-20151113/tmp 
                pip3 install --user --verbose --no-cache-dir spacy
                exit
                ;;
	                 
            test)
                echo " Run test"
		export PATH=.:$MY_INTEL_PATH:$PATH
                python3 setup.py test
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
