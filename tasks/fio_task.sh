#!/bin/bash

PREFIX=""
TASK_TYPE=""
INDEX=""
BS=""
IO_DEPTH=""
SIZE=10G

TEST_DIR=/mnt/nvme
RSLT_DIR=../results
TASK_DIR=../tasks

NICE=-10
THREADS=1

# Looping through all arguments.
for arg in "$@"; do
	# Check if the argument contains '='
    	if [[ "$arg" == *=* ]]; then
        	# Split the key and value using '=' as the delimiter
        	key="${arg%%=*}"
        	value="${arg#*=}"
		declare "$key=$value"
    	fi
done

RSLT_DIR+=/$PREFIX

# Default parameters for LC tasks.
if [[ "$TASK_TYPE" = "LC" ]]; then
	BS=${BS:=4k}
	IO_DEPTH=${IO_DEPTH:=1}
else
	BS=${BS:=64k}
	IO_DEPTH=${IO_DEPTH:=32}
fi

TASK_FILE=${TASK_DIR}/${PREFIX}.fio
FILE_NAME=${PREFIX}_${TASK_TYPE}${INDEX}

# Creating the fio job file dynamically.
echo "[${FILE_NAME}]" >> $TASK_FILE
echo "filename=${TEST_DIR}/${FILE_NAME}" >> $TASK_FILE
echo "bs=${BS}" >> $TASK_FILE
echo "iodepth=${IO_DEPTH}" >> $TASK_FILE
echo "numjobs=${THREADS}" >> $TASK_FILE
echo "nice=${NICE}" >> $TASK_FILE

# Prefilling task file.
sudo fio \
	--name=prefill \
	--rw=write \
	--ioengine=sync \
	--bs=4k \
	--size=$SIZE \
	--filename=${TEST_DIR}/${FILE_NAME} > /dev/null
