#!/bin/bash

# The build script for the program

# Paths
[ -z $SRC  ] && SRC='src'
[ -z $INC  ] && INC='inc'
[ -z $OBJ  ] && OBJ='obj'
[ -z $EXEC ] && EXEC='main'

# Compile flags
[ -z $CC     ] && CC='gcc'
CC=`which $CC`
[ -z $CFLAGS ] && CFLAGS='-Iinclude'
[ -z $LFLAGS ] && LFLAGS=''
[ -z $PKGS   ] && PKGS='x11'

# add packages
PKGCFLAGS=`pkg-config --cflags $PKGS`
PKGLFLAGS=`pkg-config --libs  $PKGS`
PKGSUCCESS=$?

# only add packages if they are found
if [ $PKGSUCCESS -eq 0 ]; then
    CFLAGS="$CFLAGS $PKGCFLAGS"
    LFLAGS="$LFLAGS $PKGLFLAGS"
fi

# Make the object directory if it doesn't exist
[ ! -d $OBJ ] && mkdir -p $OBJ

# get the object file based on the C source file
# `getobj $SRC/file.c` echoes `$OBJ/file.o`
getobj() {
    # '!' is the delimeter
    local CHANGE_PATH='s!^.*/!'$OBJ'/!'
    local CHANGE_EXT='s/\.c$/\.o/'
    echo $1 | sed $CHANGE_PATH';'$CHANGE_EXT
}

# parses a date from the `stat` "human-readable" format.
# AAAA-BB-CC DD:EE:FF.GGGGGGGGG +HHHH
# A: year
# B: month
# C: day
# D: hour
# E: minute
# F: second
# G: ms
# H: offset
# example: `parse_date 'year' '2022-01-01 01:01:01.000000000 +000'` echoes '2022'.
parse_date() {
    local DATE=`echo $2 | cut -d ' ' -f 1`
    local TIME=`echo $2 | cut -d ' ' -f 2`
    local OFFSET=`echo $2 | cut -d ' ' -f 3`

    case $1 in
        'year')   echo $DATE | cut -d '-' -f 1 ;;
        'month')  echo $DATE | cut -d '-' -f 2 ;;
        'day')    echo $DATE | cut -d '-' -f 3 ;;

        'hour')   echo $TIME | cut -d ':' -f 1 ;;
        'minute') echo $TIME | cut -d ':' -f 2 ;;
        'second') echo $TIME | cut -d ':' -f 3 | cut -d '.' -f 1 ;;
        'ms')     echo $TIME | cut -d ':' -f 3 | cut -d '.' -f 2 ;;

        'offset') echo ${OFFSET:1}
    esac
}

# returns 0 when source file has changed
# If obj file is older than source file, then source file has changed
src_changed() {
    [ ! -f $1 ] && return 0
    OBJ_FILE=`getobj $1`
    [ ! -f $OBJ_FILE ] && return 0

    STAT_SRC=`stat $1        -c '%y'`
    STAT_OBJ=`stat $OBJ_FILE -c '%y'`

    for unit in year month day hour minute second ms; do
        UNIT_SRC=`parse_date $unit "$STAT_SRC"`
        UNIT_OBJ=`parse_date $unit "$STAT_OBJ"`
        [ $UNIT_SRC -gt $UNIT_OBJ ] && return 0
        [ $UNIT_SRC -lt $UNIT_OBJ ] && return 1
    done

    return 1
}

COMP_CMDS=''

# compile a single C file to an object file
# `c2obj $SRC/file.c` compiles `$SRC/file.c` to `$OBJ/file.o`
c2obj() {
    local CMD="$CC -c -o `getobj $1` $1 $CFLAGS"

    local COMP_CMD=`comp_cmd_file $1 "$CMD"`
    [ -z "$COMP_CMDS" ] && COMP_CMDS="[$COMP_CMD" || COMP_CMDS="$COMP_CMDS,$COMP_CMD"
    echo $CMD
    $CMD
}

# comp_cmd_file [file] [command]
comp_cmd_file() {
    printf '{"directory":"%s","command":"%s","file":"%s"}' $PWD "$2" "$1"
}

to_json_array() {
    local ARR=''

    for word in $@; do
        [ -z $ARR ] && ARR="[\"$word\"" || ARR="$ARR,\"word\""
    done

    ARR="$ARR]"
    echo $ARR
}

# compiles all the objects to an executable
# no arguments needed
objs2exec() {
    local CMD="$CC -o $EXEC $OBJ/*.o $CFLAGS $LFLAGS"
    echo $CMD
    $CMD
}

# compile the files
OBJ_COMPILED=0
NUM_FILES=0
for file in `ls $SRC`; do
    (( NUM_FILES++ ))
    if src_changed $SRC/$file; then
        (( OBJ_COMPILED++ ))
        c2obj $SRC/$file
    fi
done
[ $OBJ_COMPILED -gt 0 ] && objs2exec || echo 'already built'

COMP_CMDS="$COMP_CMDS]"
[ $OBJ_COMPILED -eq $NUM_FILES ] && echo "$COMP_CMDS" > compile_commands.json
