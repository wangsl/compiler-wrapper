#!/bin/sh

# $Id$

for src in "$*"; do
     svn propset svn:keywords "Id" $src
done

exit
