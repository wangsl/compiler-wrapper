#!/bin/sh

# $Id$

compilers="cc c++ f77 g++ g77 gcc gfortran icc icpc ifort mpic++ mpicc mpiCC mpicxx mpif77 mpif90 pgf77 pgf90 pgfortran pgcc pgc++"

for comp in $compilers;  do
    echo $comp
    ln -s intel-wrapper.sh $comp
done
