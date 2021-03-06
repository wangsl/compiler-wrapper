#!/bin/bash 

# GitHub: git@github.com:wangsl/compiler-wrapper.git

# $Id: intel-wrapper.sh 45 2014-04-20 16:18:09Z wangsl2001@gmail.com $

svn_id="$Id: intel-wrapper.sh 45 2014-04-20 16:18:09Z wangsl2001@gmail.com $"

shopt -s expand_aliases

alias die='_error_exit_ "Error in file $0 at line $LINENO\n"'
alias warn='_warn_ "Warn in file $0 at line $LINENO\n"'

# to print out environment variables

function help()
{
    local environment_variables=(
	DEBUG_MODE
	BUILD_WRAPPER_SCRIPT
	SPECIAL_RULES_FUNCTION
	SOURCE_CODE_LIST_WITH_INTEL_COMPILERS
	SOURCE_CODE_LIST_WITH_GNU_COMPILERS
	REGULAR_EXPRESSION_LIST_FOR_SOURCE_CODE_WITH_INTEL_COMPILERS
	REGULAR_EXPRESSION_LIST_FOR_SOURCE_CODE_WITH_GNU_COMPILERS
	INVALID_FLAGS_FOR_INTEL_COMPILERS
	INVALID_FLAGS_FOR_GNU_COMPILERS
	OPTIMIZATION_FLAGS
	OPTIMIZATION_FLAGS_FOR_INTEL_COMPILERS
	OPTIMIZATION_FLAGS_FOR_INTEL_FORTRAN_COMPILERS
	OPTIMIZATION_FLAGS_FOR_GNU_COMPILERS
	OPTIMIZATION_FLAGS_FOR_GNU_FORTRAN_COMPILERS
	INCLUDE_FLAGS
	INCLUDE_FLAGS_FOR_INTEL_COMPILERS
	INCLUDE_FLAGS_FOR_INTEL_FORTRAN_COMPILERS
	INCLUDE_FLAGS_FOR_GNU_COMPILERS
	INCLUDE_FLAGS_FOR_GNU_FORTRAN_COMPILERS
	LINK_FLAGS
	LINK_FLAGS_FOR_INTEL_COMPILERS
	LINK_FLAGS_FOR_GNU_COMPILERS
	EXTRA_LINK_FLAGS
	EXTRA_OBJECT_FILE_AND_LIBRARY_LIST
	STRING_MACROS
	NON_STRING_MACROS
	FUNCTION_MACROS
	INVALID_MACROS
	INTEL_BIN_PATH
	GNU_BIN_PATH
	INTEL_MPI_BIN_PATH
	GNU_MPI_BIN_PATH
	DEFAULT_COMPILER
	NO_ECHO_FLAGS
	ECHO_BY_DEFAULT
	REGULAR_EXPRESSIONS_FOR_NO_ECHO
	STRING_PREPEND_TO_ECHO
	DEBUG_LOG_FILE
	ECHO_TO_LOG_FILE_AND_STDOUT

	NVCC_BIN_PATH
	INCLUDE_FLAGS_FOR_NVCC_CONPILERS
	INVALID_FLAGS_FOR_NVCC_COMPILERS
	OPTIMIZATION_FLAGS_FOR_NVCC_COMPILERS
	)
    
    echo
    echo " Environment variables:"
    echo
    local e=
    for e in ${environment_variables[*]}; do
	echo " #export $e="
    done
    echo
}

function set_input_compiler_name()
{
    local arg="$*"
    Input_compiler_name=$(basename $arg)
}

function check_string_and_function_macro()
{
    local arg="$*"

# check invalid macros
    
    local invalid_macros=$(sort_and_uniq $INVALID_MACROS)
    local macro=
    for macro in $invalid_macros; do    
	if [ "$arg" == "$macro" ]; then
	    echo ""
	    return
	fi
    done

    local _macro_function=1
    local _macro_string=10
    local _macro_non_string=100

    local macro_type=0

    if [[ $arg =~ ^-D[a-zA-Z0-9_]*\( ]]; then
	macro_type=${_macro_function} 
    elif [[ $arg =~ ^-D[a-zA-Z0-9_]*=\" ]]; then
	macro_type=${_macro_string};
    elif [[ $arg =~ ^-D[a-zA-Z0-9_]*= ]]; then
	macro_type=${_macro_non_string}	
    fi
    
## It seems we do not need FUNCTION_MACROS, STRING_MACROS and NON_STRING_MACROS

    local function_macros=$(sort_and_uniq $FUNCTION_MACROS)
    local macro=
    for macro in $function_macros; do
	if [[ $arg =~ ^-D$macro\( ]]; then
	    macro_type=${_macro_function}; 
	fi
    done

    local string_macros=$(sort_and_uniq $STRING_MACROS)
    local macro=
    for macro in $string_macros; do
	if [[ $arg =~ ^-D$macro= ]]; then
	    macro_type=${_macro_string}
	fi
    done
    
    local non_string_macros=$(sort_and_uniq $NON_STRING_MACROS)
    for macro in $non_string_macros; do
	if [[ $arg =~ ^-D$macro= ]]; then
	    macro_type=${_macro_non_string}
	fi
    done

    local macro_string=""
    if [ $macro_type -eq ${_macro_function} ]; then
	macro_string=$(echo $arg'"' | sed -e 's#^-D#-D"#')
    elif [ $macro_type -eq ${_macro_non_string} -o \
	$macro_type -eq ${_macro_string} ]; then
        macro_string=$(echo $arg | sed 's#[ "()<>]#\\&#g') 
    fi

    echo "$macro_string"
}

function _set_compiler_type_for_source_code()
{
    # Global variables
    # Source_code_list, Source_code_regular_expression_list

    # Set_compiler_by_source_code, Set_compiler_by_regular_expression

    local args="$General_arguments"

    Set_compiler_by_source_code=0
    Set_compiler_by_regular_expression=0

    local arg=
    for arg in $args; do
	local src=
	for src in $Source_code_list; do
	    if [[ $arg =~ $src$ ]]; then
		Set_compiler_by_source_code=1
		break
	    fi
	done

	local reg=
	for reg in $Source_code_regular_expression_list; do
	    if [[ $arg =~ $reg ]]; then
		Set_compiler_by_regular_expression=1
		break
	    fi
	done
    done
}

function set_compiler_type_for_source_code()
{
    # GNU compilers

    Source_code_list=$(sort_and_uniq $SOURCE_CODE_LIST_WITH_GNU_COMPILERS)
    Source_code_regular_expression_list=$REGULAR_EXPRESSION_LIST_FOR_SOURCE_CODE_WITH_GNU_COMPILERS
    _set_compiler_type_for_source_code
    local use_gnu_compiler_by_source_code=$Set_compiler_by_source_code
    local use_gnu_compiler_by_regular_expression=$Set_compiler_by_regular_expression

    # Intel compilers

    Source_code_list=$(sort_and_uniq $SOURCE_CODE_LIST_WITH_INTEL_COMPILERS)
    Source_code_regular_expression_list=$REGULAR_EXPRESSION_LIST_FOR_SOURCE_CODE_WITH_INTEL_COMPILERS
    _set_compiler_type_for_source_code
    local use_intel_compiler_by_source_code=$Set_compiler_by_source_code
    local use_intel_compiler_by_regular_expression=$Set_compiler_by_regular_expression
    
    if [ $use_gnu_compiler_by_source_code -eq 1 -a \
	$use_intel_compiler_by_source_code -eq 1 ]; then
	die " Can not use both GNU and Intel compilers by source code list"
    fi

    if [ $use_gnu_compiler_by_regular_expression -eq 1 -a \
	$use_intel_compiler_by_regular_expression -eq 1 ]; then
	die " Can not use both GNU and Intel compilers by regular expression list"
    fi

    # check the default compiler

    Use_gnu_compiler=0
    Use_intel_compiler=1
    Use_nvcc_compiler=0

    if [ "$DEFAULT_COMPILER" != "" ]; then
	if [ "$DEFAULT_COMPILER" == "GNU" ]; then
	    Use_gnu_compiler=1
	    Use_intel_compiler=0
	elif [ "$DEFAULT_COMPILER" == "INTEL" ]; then
	    Use_gnu_compiler=0
	    Use_intel_compiler=1
	else
	    die " DEFAULT_COMPLIER can only be 'GNU' or 'INTEL'"
	fi
    fi

    if [ $use_gnu_compiler_by_regular_expression -eq 1 ]; then
	Use_gnu_compiler=1
	Use_intel_compiler=0
    elif [ $use_intel_compiler_by_regular_expression -eq 1 ]; then
	Use_gnu_compiler=0
	Use_intel_compiler=1
    fi

    if [ $use_gnu_compiler_by_source_code -eq 1 ]; then
	Use_gnu_compiler=1
	Use_intel_compiler=0
    elif [ $use_intel_compiler_by_source_code -eq 1 ]; then
	Use_gnu_compiler=0
	Use_intel_compiler=1
    fi

    Source_code_list=
    Source_code_regular_expression_list=
    Set_compiler_by_source_code=
    Set_compiler_by_regular_expression=
}

function _set_compiler_path()
{
    local path=

    if [ $# -eq 2 ]; then
    	path="$2"
    elif [ $# -eq 1 ]; then
	path="$1"
    else
	die " Argument number error, should be 2, it is $#"
    fi
    
    echo $path | sed -e 's#/*$##'
}

function _set_nvcc_compiler()
{
    Use_gnu_compiler=0
    Use_intel_compiler=0
    Use_nvcc_compiler=1
    
    local compiler_name="nvcc"
    local path=$(_set_compiler_path $Pre_defined_nvcc_bin_path $NVCC_BIN_PATH)
    Compiler="$path/$compiler_name"
    
    if [ ! -x $Compiler ]; then
	die " $Compiler is not a valid file"
    fi
    
    _prepend_gnu_bin_path
}

function _prepend_gnu_bin_path()
{
    # For Intel and nvcc compilers, the original GNU compilers should be found first in PATH
    
    path=$(_set_compiler_path $Pre_defined_gnu_bin_path $GNU_BIN_PATH)
    if [ "$path" == "" ]; then
	die " GNU_BIN_PATH error"
    elif [ ! -e $path ]; then
	die " GNU_BIN_PATH error"
    fi
    export PATH=.:$path:$PATH
}

function set_compiler()
{
    if [ "$Input_compiler_name" == "nvcc" ]; then
	_set_nvcc_compiler
	return
    fi

    if [ $Use_gnu_compiler -eq 1 -a $Use_intel_compiler -eq 1 ]; then
	die " Can not set both Use_gnu_compiler and Use_intel_compiler"
    fi
    
    if [ $Use_gnu_compiler -eq 0 -a $Use_intel_compiler -eq 0 ]; then
	die " No Use_gnu_compiler or Use_intel_compiler has been set"
    fi
    
    Fortran_compiler=0

    local compiler_name=
    local path=

    if [ $Use_gnu_compiler -eq 1 ]; then

	path=$(_set_compiler_path $Pre_defined_gnu_bin_path $GNU_BIN_PATH)

	case $Input_compiler_name in
	    
	    mpi*)
		compiler_name=$Input_compiler_name
		path=$(_set_compiler_path $Pre_defined_gnu_mpi_bin_path $GNU_MPI_BIN_PATH)
		if [ "$Input_compiler_name" == "mpif77" -o "$Input_compiler_name" == "mpif90" ]; then
		    Fortran_compiler=1
		fi
		;;

	    icpc|g++|c++|pgc++|clang++)
		compiler_name=g++
		;;

	    icc|gcc|cc|pgcc)
		compiler_name=gcc
		;;

	    ifort|gfortran|g77|f77|f95|pgf77|pgf90|pgf95|pgfortran)
		compiler_name=gfortran
		Fortran_compiler=1
		;;

	    *)
		die " No idea about input compiler: $Input_compiler_name"
		;;
	esac
    fi
    
    if [ $Use_intel_compiler -eq 1 ]; then

	path=$(_set_compiler_path $Pre_defined_intel_bin_path $INTEL_BIN_PATH)

	case $Input_compiler_name in
	    
	    mpi*)
		compiler_name=$Input_compiler_name
		path=$(_set_compiler_path $Pre_defined_intel_mpi_bin_path $INTEL_MPI_BIN_PATH)
		if [ "$Input_compiler_name" == "mpif77" -o "$Input_compiler_name" == "mpif90" ]; then
		    Fortran_compiler=1
		fi
		;;

	    icpc|g++|c++|pgc++|clang++)
		compiler_name=icpc
		;;

	    icc|gcc|cc|pgcc)
		compiler_name=icc
		;;

	    ifort|gfortran|g77|f77|f95|pgf77|pgf90|pgf95|pgfortran)
		compiler_name=ifort
		Fortran_compiler=1
		;;

	    *)
		die " No idea about input compiler: $Input_compiler_name"
		;;
	esac
    fi
    
    if [ "$path" == "" ]; then
	die " compiler path error"
    fi

    if [ "$compiler_name" == "" ]; then
	die " compiler name error"
    fi

    Compiler="$path/$compiler_name"

    if [ ! -x $Compiler ]; then
	die " $Compiler is not a valid file"
    fi

    # For Intel compilers, the original GNU compilers should be found first in PATH

    _prepend_gnu_bin_path
}

function _skip_invalid_flags()
{
    # Global variables
    # Invalid_flags

    # Valid_arguments

    local args="$General_arguments"
    
    Valid_arguments=
    local arg=
    for arg in $args; do
	local is_valid_arg=1
	local invalid_flag=
	for invalid_flag in $Invalid_flags; do
	    if [ "$arg" == "$invalid_flag" ]; then
		is_valid_arg=0
		break
	    fi
	done
	
	if [ $is_valid_arg -eq 1 ]; then
	    Valid_arguments="$Valid_arguments $arg"
	fi
    done
}

function skip_invalid_flags()
{
    Invalid_flags=

    if [ $Use_intel_compiler -eq 1 ]; then
	Invalid_flags="${Pre_defined_invalid_flags_for_intel_compilers[*]}"
	Invalid_flags="$Invalid_flags $INVALID_FLAGS_FOR_INTEL_COMPILERS"
    fi

    if [ $Use_gnu_compiler -eq 1 ]; then
	Invalid_flags="${Pre_defined_invalid_flags_for_gnu_compilers[*]}"
	Invalid_flags="$Invalid_flags $INVALID_FLAGS_FOR_GNU_COMPILERS"
    fi

    if [ $Use_nvcc_compiler -eq 1 ]; then
	Invalid_flags="${Pre_defined_invalid_flags_for_nvcc_compilers[*]}"
	Invalid_flags="$Invalid_flags $INVALID_FLAGS_FOR_NVCC_COMPILERS"
    fi

    Invalid_flags="${Invalid_flags} $INVALID_MACROS"
    
    _skip_invalid_flags
    
    Invalid_flags=
}

function check_compile_or_link()
{
    local args="$General_arguments"
   
    local compile=0
    local link=1
    local pre_process=0
    
    local arg=
    for arg in $args; do
	if [ "$arg" == "-c" -o "$arg" == "--device-c" -o "$arg" == "-dc" -o \
	    "$arg" == "--device-link" -o "$arg" == "-dlink" ]; then 
	    compile=1;
	elif [ "$arg" == "-o" ]; then 
	    link=1; 
	elif [ "$arg" == "-M" -o "$arg" == "-MM" -o "$arg" == "-E" -o "$arg" == "-v" ]; then
	    pre_process=1
	fi
    done

    Pre_process=0

    if [ $pre_process -eq 1 ]; then
	Pre_process=1
	Is_to_compile=1
	Is_to_link=0
    elif [ $compile -eq 1 ]; then
	Is_to_compile=1
	Is_to_link=0
    elif [ $link -eq 1 ]; then
	Is_to_compile=0
	Is_to_link=1
    fi
}

function _setup_compile_and_link_flags()
{
    # Global variables
    # Compiler_include_flags Compiler_optimization_flags 
    # Compiler_link_flags
    
    # Compile_flags Link_flags
    
    Compile_flags=
    Link_flags=

    if [ $Is_to_compile -eq 0 -a $Is_to_link -eq 0 ]; then
	return
    fi
    
    Compile_flags="$Compile_flags $INCLUDE_FLAGS"
    Compile_flags="$Compile_flags $Compiler_include_flags"
    Compile_flags="$Compile_flags $OPTIMIZATION_FLAGS"
    Compile_flags="$Compile_flags $Compiler_optimization_flags" 

    if [ $Is_to_link -eq 0 ]; then
	return
    fi

    Link_flags="$Link_flags $LINK_FLAGS"
    Link_flags="$Link_flags $Compiler_link_flags"
}

function setup_compile_and_link_flags()
{
    Compiler_include_flags=
    Compiler_optimization_flags=
    Compiler_link_flags=
    
    if [ $Use_gnu_compiler -eq 1 ]; then
	if [ $Fortran_compiler -eq 1 ]; then
	    Compiler_include_flags=$INCLUDE_FLAGS_FOR_GNU_FORTRAN_COMPILERS
	    Compiler_optimization_flags=$OPTIMIZATION_FLAGS_FOR_GNU_FORTRAN_COMPILERS
	else
	    Compiler_include_flags=$INCLUDE_FLAGS_FOR_GNU_COMPILERS
	    Compiler_optimization_flags=$OPTIMIZATION_FLAGS_FOR_GNU_COMPILERS
	fi
	Compiler_link_flags=$LINK_FLAGS_FOR_GNU_COMPILERS
    fi

    if [ $Use_intel_compiler -eq 1 ]; then
	if [ $Fortran_compiler -eq 1 ]; then
	    Compiler_include_flags=$INCLUDE_FLAGS_FOR_INTEL_FORTRAN_COMPILERS
	    Compiler_optimization_flags=$OPTIMIZATION_FLAGS_FOR_INTEL_FORTRAN_COMPILERS
	else
	    Compiler_include_flags=$INCLUDE_FLAGS_FOR_INTEL_COMPILERS
	    Compiler_optimization_flags=$OPTIMIZATION_FLAGS_FOR_INTEL_COMPILERS
	fi
	Compiler_link_flags=$LINK_FLAGS_FOR_INTEL_COMPILERS
    fi

    if [ $Use_nvcc_compiler -eq 1 ]; then
	Compiler_include_flags=$INCLUDE_FLAGS_FOR_NVCC_COMPILERS
	Compiler_optimization_flags=$OPTIMIZATION_FLAGS_FOR_NVCC_COMPILERS
    fi
    
    _setup_compile_and_link_flags

    Compiler_include_flags=
    Compiler_optimization_flags=
    Compiler_link_flags=
}

function setup_extra_link_flags()
{
    Extra_link_flags=
    
    if [ $Is_to_link -eq 0 ]; then return; fi

    local extra_object_file_and_library_list=$EXTRA_OBJECT_FILE_AND_LIBRARY_LIST
    local file=
    for file in $extra_object_file_and_library_list; do
	if [ -e $file ]; then
	    Extra_link_flags="$Extra_link_flags $file" 
	fi
    done

    Extra_link_flags="$Extra_link_flags $EXTRA_LINK_FLAGS" 
}

function setup_echo_flags()
{
    Do_echo=1

    if [ "$ECHO_BY_DEFAULT" != "" ]; then
	if [ "$ECHO_BY_DEFAULT" == "NO" ]; then
	    Do_echo=0
	elif [ "$ECHO_BY_DEFAULT" == "YES" ]; then
	    Do_echo=1
	else
	    die "ECHO_BY_DEFAULT can only be 'YES' or 'NO'"
	fi
	return
    fi

    if [ $Pre_process -eq 1 ]; then
	Do_echo=0
	return
    fi

    local args="$General_arguments"

    local no_echo_flags="$NO_ECHO_FLAGS"
    no_echo_flags="$no_echo_flags ${Pre_defined_no_echo_flags[*]}"

    local no_echo_regular_expressions="$REGULAR_EXPRESSIONS_FOR_NO_ECHO"
    no_echo_regular_expressions="$no_echo_regular_expressions ${Pre_defined_no_echo_regular_expressions[*]}"

    local arg=
    for arg in $args; do
	local flag=
	for flag in $no_echo_flags; do
	    if [ "$arg" == "$flag" ]; then
		Do_echo=0
		return
	    fi
	done
	
	local reg=
	for reg in $no_echo_regular_expressions; do
	    if [[ $arg =~ $reg ]]; then
		Do_echo=0
		return
	    fi
	done
    done
}

##### Pre-defined data #####

Pre_defined_invalid_flags_for_intel_compilers=(
    -ansi-alias -falign-stack=maintain-16-byte 
    -m3dnow -msse4.1 -msse4.2 -mssse3 -pedantic 
    -W -Waggregate-return -Wcast-align -Wchar-subscripts
    -Wdeclaration-after-statement -Wextra -Wfloat-equal 
    -Wimplicit -Winvalid-pch -Wnested-externs -Wno-address 
    -Wno-long-long -Wno-pointer-sign -Wno-sign-compare 
    -Wno-unused-parameter -Wparentheses -Wredundant-decls 
    -Wsign-compare -Wswitch -fopenmp -ffast-math -xhost
    -Wno-unused-result -Wno-unused-value
    -march=native
    )

Pre_defined_invalid_flags_for_gnu_compilers=(
    -132 -Zp8 -vec-report -par-report -shared-intel 
    -xO -axO -xP -axP -ip -xOP -axOP -xSSE3 -axSSE3 
    -align -Wno-deprecated -openmp -openmp-report -xhost
    -march=native
)

Pre_defined_invalid_flags_for_nvcc_compilers=()

Pre_defined_no_echo_flags=(
    -V --version -logo -dumpmachine -dumpversion
    -E -EP -P -C -v -help
)

Pre_defined_no_echo_regular_expressions=(
    ^-print-prog-name=
)

Pre_defined_gnu_bin_path="/usr/bin"
Pre_defined_intel_bin_path=
Pre_defined_intel_mpi_bin_path=
Pre_defined_gnu_mpi_bin_path=
Pre_defined_nvcc_bin_path=

#################################
#                               #
#         main part             #
#                               #
#################################

#export ECHO_TO_LOG_FILE_AND_STDOUT="YES"

# this is for bazel hacking or scosn
if [ "$HOME" == "" ]; then
    env_log=/state/partition1/wang/env.log
    if [ -e $env_log ]; then
	while read -r line; do
            export "$line"
	done < $env_log
    fi
fi

# please also add this to main function
#    local env_log=/mnt/ramfs/tmp/env.log
#    rm -rf $env_log
#    env | grep -v '{' | grep -v '}' | grep -v '()' | grep -v _= > $env_log

util=$MY_INTEL_PATH/util.sh
if [ -e $util ]; then
    source $util
else
    echo " $util does not exist"
    exit 1
fi

# print out all the environment variables

if [ "$DEBUG_MODE" == "YES" ]; then 
    set -x
fi

if [ "$1" == "-h" ]; then
    help
    exit
fi

# get input compiler name

Input_compiler_name=
set_input_compiler_name "$0"
export COMPILER_NAME=$Input_compiler_name

if [ "$SPECIAL_RULES_FUNCTION" != "" ]; then
    if [ -e $BUILD_WRAPPER_SCRIPT ]; then
	export TO_SOURCE_BUILD_WRAPPER_SCRIPT=1
	source $BUILD_WRAPPER_SCRIPT
	export TO_SOURCE_BUILD_WRAPPER_SCRIPT=
	declare -f $SPECIAL_RULES_FUNCTION > /dev/null 2>&1
	if [[ $? != 0 ]]; then
	    die "Function $SPECIAL_RULES_FUNCTION does not exist"
	fi
	$SPECIAL_RULES_FUNCTION $*
    fi
fi

if [ "$COMPILER_NAME" != "$Input_compiler_name" ]; then
    Input_compiler_name=$COMPILER_NAME
fi

if [ "$DEBUG_LOG_FILE" != "" ]; then
    {
	echo 
	echo "-------" 
	cecho "green" "$0 $*"
    } >> $DEBUG_LOG_FILE 2>&1
fi

# seperate macro for string and functions (special macros)

Special_macro_arguments=
General_arguments=
macro=
while [ $# -gt 0 ]; do
    arg="$1"
    shift
    if [ "$arg" == "-D" -o \
	"$arg" == "-L" -o "$arg" == "-l" -o \
	"$arg" == "-I" ]; then
	arg="${arg}$1"
	shift
    fi
    macro=$(check_string_and_function_macro $arg)
    if [ "$macro" == "" ]; then
	General_arguments="$General_arguments $arg"	
    else
	Special_macro_arguments="$Special_macro_arguments $macro"
    fi
done
unset macro

Use_gnu_compiler=
Use_intel_compiler=
Use_nvcc_compiler=
set_compiler_type_for_source_code

Fortran_compiler=
Compiler=
set_compiler

Valid_arguments=
skip_invalid_flags

Is_to_compile=
Is_to_link=
Pre_process=
check_compile_or_link

Compile_flags=
Link_flags=
setup_compile_and_link_flags

Extra_link_flags=
setup_extra_link_flags

Do_echo=
setup_echo_flags

command=

if [ $Pre_process -eq 1 ]; then
    command="$Compiler $Compile_flags $Special_macro_arguments $Valid_arguments"
else
    command="$Compiler $Compile_flags $Special_macro_arguments $Link_flags $Valid_arguments"
    command="$command $Extra_link_flags"
fi

if [ $Do_echo -eq 1 ]; then
    if [ "$STRING_PREPEND_TO_ECHO" != "" ]; then echo -n $STRING_PREPEND_TO_ECHO; fi
    for((i=0; i<90; i++)); do echo -n "-"; done; echo
    if [ "$STRING_PREPEND_TO_ECHO" != "" ]; then echo -n $STRING_PREPEND_TO_ECHO; fi
    cecho "blue" "$command"
    echo 
fi

if [ "$DEBUG_LOG_FILE" != "" ]; then
    cecho "blue" "$command" >> $DEBUG_LOG_FILE 2>&1
    if [ "$ECHO_TO_LOG_FILE_AND_STDOUT" == "NO" ]; then
	eval "$command" >> $DEBUG_LOG_FILE 2>&1
    else
	eval "$command" 2>&1 | tee -a $DEBUG_LOG_FILE 
    fi
else
    eval "$command"
fi

if [ $? -ne 0 ]; then
    if [ $Do_echo -eq 1 ]; then
	cecho "magenta" " $command"
	die "Compilation failed: $command"
    fi
fi

