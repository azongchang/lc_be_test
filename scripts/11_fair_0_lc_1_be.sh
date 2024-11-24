#!/bin/bash

BENCH=randread
ENGINE=libaio
SIZE=10G
RUN_TIME=3600
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

rm -r ${TEST_DIR}/* 2> /dev/null

#mkdir -p ${RSLT_DIR}/${BASE_NAME} 2> /dev/null

TASK_FILE=${TASK_DIR}/${BASE_NAME}.fio
#rm $TASK_FILE 2> /dev/null
echo "[global]" > $TASK_FILE
echo "ioengine=${ENGINE}" >> $TASK_FILE
echo "direct=1" >> $TASK_FILE
echo "rw=${BENCH}" >> $TASK_FILE
echo "size=${SIZE}" >> $TASK_FILE
echo "time_based=1" >> $TASK_FILE
echo "runtime=${RUN_TIME}s" >> $TASK_FILE
echo "cpus_allowed=$CPUS" >> $TASK_FILE
echo "cpus_allowed_policy=shared" >> $TASK_FILE
#echo "group_reporting=1" >> $TASK_FILE

# Configuring BE tasks.
for i in `seq 0 $(expr $BE_NUM - 1)`
do
	${TASK_DIR}/fio_task.sh PREFIX=$BASE_NAME TASK_TYPE=BE INDEX=$i SIZE=$SIZE CPUS=$CPUS NICE=$NICE &
done

wait
sync && wait

mkdir -p ${TEST_DIR}/db_dir
mkdir -p ${TEST_DIR}/wal_dir

# Prefilling DB
/home/zzh/rocksdb/db_bench \
	-benchmarks=fillseq \
	-block_size=4096 \
	-key_size=16 \
	-value_size=64 \
	-num=1000000 \
	-compression_type=none \
	-use_existing_db=0 \
	-db=${TEST_DIR}/db_dir \
	-wal_dir=${TEST_DIR}/wal_dir > /dev/null 2>&1 &
wait
sync && wait

#blktrace -d /dev/nvme0n1 -o - | blkparse -i - -o ${RSLT_DIR}/${BASE_NAME}_blktrace &

# Running LC task(s)
time taskset -c $CPUS \
	nice -n $NICE \
	/home/zzh/rocksdb/db_bench \
	-benchmarks=readrandom \
	-use_direct_reads=1 \
	-block_size=4096 \
	-key_size=16 \
	-value_size=64 \
	-num=1000000 \
	-compression_type=none \
	-duration=$RUN_TIME \
	-threads=$THREADS \
	-use_existing_db=1 \
	-db=${TEST_DIR}/db_dir \
	-wal_dir=${TEST_DIR}/wal_dir > /dev/null 2>&1 &
PID_LC=$!

# Noticing that the data prefill is completed during creating the fio configuration.
# Running BE task(s)
time fio $TASK_FILE > /dev/null &
PID_BE=$!

while kill -0 "$PID_LC" 2>/dev/null; do
	sleep 0.1
done
echo "LC task(s) done."
while kill -0 "$PID_BE" 2>/dev/null; do
	sleep 0.1
done
echo "BE task(s) done."

pkill -9 blktrace
sync && wait
echo "$BASE_NAME done."
