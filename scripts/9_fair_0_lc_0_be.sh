#!/bin/bash

BENCH=randread
ENGINE=libaio
RUN_TIME=60
CPUS=12
THREADS=1
NICE=-10

TEST_DIR=/mnt/nvme
TASK_DIR=../tasks
RSLT_DIR=../results

BASE_NAME=$(basename "$0" .sh)
NUMBERS=$(echo "$BASE_NAME" | sed -E 's/([0-9]+)_.*_([0-9]+)_.*_([0-9]+).*/\2 \3/')
read LC_NUM BE_NUM <<< "$NUMBERS"

echo "Tesing $LC_NUM LC task(s) and $BE_NUM BE task(s)."

#rm -r ${TEST_DIR}/* 2> /dev/null
for i in `seq 0 $(expr $LC_NUM + $BE_NUM - 1)`
do
	mkdir -p ${TEST_DIR}/task$i
done

mkdir -p ${RSLT_DIR}/${BASE_NAME} 2> /dev/null

TASK_FILE=${TASK_DIR}/${BASE_NAME}.fio
#rm $TASK_FILE 2> /dev/null
echo "[global]" > $TASK_FILE
echo "ioengine=${ENGINE}" >> $TASK_FILE
echo "direct=1" >> $TASK_FILE
echo "rw=${BENCH}" >> $TASK_FILE
echo "size=100G" >> $TASK_FILE
echo "time_based=1" >> $TASK_FILE
echo "runtime=${RUN_TIME}s" >> $TASK_FILE
echo "cpus_allowed=$CPUS" >> $TASK_FILE
echo "cpus_allowed_policy=shared" >> $TASK_FILE
#echo "group_reporting=1" >> $TASK_FILE

# Running LC tasks.
for i in `seq 0 $(expr $LC_NUM - 1)`
do
	${TASK_DIR}/fio_task.sh PREFIX=$BASE_NAME TASK_TYPE=LC INDEX=$i CPUS=$CPUS NICE=$NICE
done

# Running BE tasks.
for i in `seq 0 $(expr $BE_NUM - 1)`
do
	${TASK_DIR}/fio_task.sh PREFIX=$BASE_NAME TASK_TYPE=BE INDEX=$i CPUS=$CPUS NICE=$NICE
done

mkdir -p /mnt/nvme/db_dir
mkdir -p /mnt/nvme/wal_dir

time taskset -c $CPUS nice -n $NICE /home/zzh/rocksdb/db_bench -benchmarks=readrandom \
	-disable_auto_compactions=1 -use_direct_reads=0 -block_size=4096 -key_size=16 \
	-value_size=64 -num=1000000 -compression_type=none -duration=$RUN_TIME -threads=$THREADS -use_existing_db=0 \
	-db=/mnt/nvme/db_dir -wal_dir=/mnt/nvme/wal_dir > /dev/null 2>&1 &
wait
echo "$BASE_NAME done."
