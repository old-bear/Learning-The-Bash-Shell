#!/bin/bash
######################################################################
# Author: jrjbear@gmail.com
# Date: Sat Jan 25 17:57:55 2014
# File: kcd.sh
#
# Usage: kcd old new 
# Description: kcd takes the pathname of `PWD' and tries to replace
# string `old' with `new'. If succeeds, `cd' to the resulting directory
######################################################################

function kcd()
{
    local newdir=""
    case "$#" in
        0 | 1) 
            builtin cd $1 ;;
        2    ) 
            if echo "${PWD}" | grep "$1" > /dev/null; then
                newdir="${PWD//$1/$2}"
                builtin cd "${newdir}"
            else
                echo "bash: cd: bad substitution" >&2
                return 1
            fi ;;
        *    )
            echo "bash: cd: wrong arg count" 1>&2
            return 1 ;;
    esac
}