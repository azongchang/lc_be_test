#!/bin/bash

PREFIX=""
TASK_TYPE=""
INDEX=""
BS=""
IO_DEPTH=""

DB_HOME=/root/rocksdb-9.7.4
TEST_DIR=/mnt/nvme/
RSLT_DIR=results
TASK_DIR=tasks

NICE=-10
BENCH=randread
ENGINE=libaio
RUN_TIME=10
CPUS=0
THREADS=1

# Loop through all arguments
for arg in "$@"; do
	# Check if the argument contains '='
    	if [[ "$arg" == *=* ]]; then
        	# Split the key and value using '=' as the delimiter
        	key="${arg%%=*}"
        	value="${arg#*=}"
		declare "$key=$value"
    	fi
done

TEST_DIR+=task$INDEX
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
FILE_NAME=${TASK_TYPE}${INDEX}_${BENCH}_${ENGINE}_${BS}_${IO_DEPTH}_${THREADS}
# Create the fio job file dynamically
echo "[${FILE_NAME}]" >> $TASK_FILE
echo "filename=${TEST_DIR}/${FILE_NAME}" >> $TASK_FILE
echo "bs=${BS}" >> $TASK_FILE
echo "iodepth=${IO_DEPTH}" >> $TASK_FILE
echo "numjobs=${THREADS}" >> $TASK_FILE

CLOCK=$(date +"%H:%M:%S")
echo "[$CLOCK] Created $TASK_TYPE task${INDEX}: bench=${BENCH}, io_engine=${ENGINE}, bs=${BS}, io_depth=${IO_DEPTH}, cpus=${CPUS}, number_of_threads=${THREADS}, run_time=${RUN_TIME}s."
