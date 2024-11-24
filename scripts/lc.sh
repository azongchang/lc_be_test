#!/bin/bash

BENCH=randread
ENGINE=libaio
SIZE=10G
RUN_TIME=30
CPUS=12
THREADS=1
NICE=-10

TEST_DIR=/mnt/nvme
TASK_DIR=../tasks
RSLT_DIR=../results

rm -r ${TEST_DIR}/* 2> /dev/null
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

blktrace -d /dev/nvme0n1 -o - | blkparse -i - -o ${RSLT_DIR}/lc_blktrace &
PID_TR=$!

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

while kill -0 "$PID_LC" 2>/dev/null; do
	sleep 0.1
done
echo "LC task(s) done."

pkill -9 blktrace
sync && wait
echo "Done."
