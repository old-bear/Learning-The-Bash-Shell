#!/bin/bash
######################################################################
# Author: jrjbear@gmail.com
# Date: Sun Jan 26 23:38:22 2014
# File: dir_stack.sh
#
# Usage: See functions usage below
# Description: These utilities behave almost the same as bash's
# pusd/popd/dir with a little difference: popd will pop out the
# top directory iff it is equal to PWD.
######################################################################

declare -a MY_DIR_STACK

# my_pushd [+n]/[-n]/[dir]
# [dir]: Push dir on stack top and then cd to it
# [+n]:  Rotate n-th (start from stack top) directory to stack top
#        and then cd to it
# [-n]:  Rotate n-th (start from stack bottom) directory to stack top
#        and then cd to it
#     :  Swap the top two directories in stack and cd to the second
function my_pushd()
{
    local target
    declare -i n
    declare -i length=${#MY_DIR_STACK[@]}
    
    if echo "$1" | grep '^[+-][0-9]\+$' > /dev/null; then
        n=${1:1}
        local sign=${1:0:1}
        
        if (( n >= length )); then
            echo "bash: my_pushd: $1: directory stack out of range" >&2
            return 1
        fi
        
        if [[ ${sign} = '+' ]]; then
            n=length-n-1
        fi
        target="${MY_DIR_STACK[n]}"
        
        _remove_element $n
        MY_DIR_STACK[length-1]="${target}"
        if ! cd "${target}"; then
            # Remove this directory
            unset MY_DIR_STACK[length-1]
            echo "bash: my_pushd: ${target}: cannot cd into it" >&2
            return 1
        fi
        my_dirs
            
    elif [[ -z $1 ]]; then
        if (( length < 2 )); then
            echo "bash: my_pushd: no other directory" >&2
            return 1
        fi
        
        local first="${MY_DIR_STACK[length-1]}"
        local second="${MY_DIR_STACK[length-2]}"
        MY_DIR_STACK[length-1]="${second}"
        MY_DIR_STACK[length-2]="${first}"
        
        if ! cd "${second}"; then
            # Remove this directory
            unset MY_DIR_STACK[length-1]
            echo "bash: my_pushd: ${second}: cannot cd into it" >&2
            return 1
        fi
        my_dirs

    else
        if ! cd "$1"; then
            echo "bash: my_pushd: $1: cannot cd into it" >&2
            return 1
        fi

        if (( length == 0 )); then
            MY_DIR_STACK[0]="${OLDPWD}"
            length=length+1
        fi
        # PWD is the absolute path and doesn't contain `~'
        MY_DIR_STACK[length]="${PWD}"
        my_dirs
    fi
}

# my_popd [+n]/[-n]
#     :  Pop out the top directory and then cd to it
# [+n]:  Remove n-th (start from stack top) directory
# [-n]:  Remove n-th (start from stack bottom) directory
function my_popd()
{
    local target
    declare -i n
    declare -i length=${#MY_DIR_STACK[@]}
    
    if echo "$1" | grep '^[+-][0-9]\+$' > /dev/null; then
        n=${1:1}
        local sign=${1:0:1}
        
        if (( n >= length )); then
            echo "bash: my_popd: $1: directory stack out of range" >&2
            return 1
        fi
        
        if [[ ${sign} = '+' ]]; then
            n=length-n-1
        fi
        
        _remove_element $n
        unset MY_DIR_STACK[length-1]
        my_dirs
        
    else
        # Pop out the top iff it is equal to PWD
        if [[ "${PWD}" = "${MY_DIR_STACK[length-1]}" ]]; then
            unset MY_DIR_STACK[length-1]
            length=length-1
        fi

        if (( length == 0 )); then
            echo "bash: my_popd: directory stack empty" >&2
            return 1
        fi

        target="${MY_DIR_STACK[length-1]}"
        if ! cd "${target}"; then
            echo "bash: my_popd: ${target}: cannot cd into it" >&2
            unset MY_DIR_STACK[length-1]
            return 1
        fi
        my_dirs
    fi
}

# my_selectd
# Prompt the user to select a directory from current stack,
# then rotate it to the top and cd to it
function my_selectd()
{
    declare -i length=${#MY_DIR_STACK[@]}
    local saved_ps3="${PS3}"
    PS3='directory? '
    
    select dir in "${MY_DIR_STACK[@]}"; do
        if [[ -n "${dir}" ]]; then
            _remove_element $(($REPLY-1))
            MY_DIR_STACK[length-1]="${dir}"
            if ! cd "${dir}"; then
                # Remove this directory
                unset MY_DIR_STACK[length-1]
                echo "bash: my_selectd: ${dir}: cannot cd into it" >&2
                return 1
            fi
            my_dirs
        else
            echo "bash: my_selectd: invalid selection" >&2
        fi
        break
    done
    PS3="${saved_ps3}"
}

# my_dirs [-l] [+n]/[-n]
#     :  Print all the directories in stack
# [-l]:  Expand `~' as home directory
# [+n]:  Print n-th (start from stack top) directory
# [-n]:  Print n-th (start from stack bottom) directory
function my_dirs()
{
    local expand
    if [[ $1 = '-l' ]]; then
        expand=1
        shift 1
    fi

    declare -i length=${#MY_DIR_STACK[@]}
    declare -i begin=length-1
    declare -i end=0
    if echo "$1" | grep '^[+-][0-9]\+$' > /dev/null; then
        declare -i n=${1:1}
        local sign=${1:0:1}

        if (( n >= length )); then
            echo "bash: my_dirs: $1: directory stack out of range" >&2
            return 1
        fi
        
        if [[ ${sign} = '+' ]]; then
            n=length-n-1
        fi

        begin=n
        end=n
    fi
    
    for (( i = begin; i >= end; --i )); do
        if [[ -n ${expand} ]]; then
            echo -n "${MY_DIR_STACK[i]} "
        else
            echo -n "${MY_DIR_STACK[i]/#${HOME}/~} "
        fi
    done
    echo ""
}

# $1 is the index of the required element
function _remove_element()
{
    declare -i length=${#MY_DIR_STACK[@]}
    
    declare -i i=$1
    for (( ; i < length-1; ++i )); do
        MY_DIR_STACK[i]="${MY_DIR_STACK[i+1]}"
    done
}