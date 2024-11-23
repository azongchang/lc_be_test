#!/bin/bash
set -x
BENCH=randread
ENGINE=libaio
RUN_TIME=10
CPUS=0
THREADS=1

TEST_DIR=/mnt/nvme
TASK_DIR=tasks
RSLT_DIR=results

BASE_NAME=$(basename "$0" .sh)
NUMBERS=$(echo "$BASE_NAME" | sed -E 's/([0-9]+)_.*_([0-9]+)_.*_([0-9]+).*/\2 \3/')
read LC_NUM BE_NUM <<< "$NUMBERS"

echo "Tesing $LC_NUM LC task(s) and $BE_NUM BE task(s)."

rm -r ${TEST_DIR}/* 2> /dev/null
for i in `seq 0 $(expr $LC_NUM + $BE_NUM - 1)`
do
	mkdir ${TEST_DIR}/task$i
done

mkdir ${RSLT_DIR}/${BASE_NAME} 2> /dev/null

TASK_FILE=${TASK_DIR}/${BASE_NAME}.fio
rm $TASK_FILE 2> /dev/null
echo "[global]" >> $TASK_FILE
echo "ioengine=${ENGINE}" >> $TASK_FILE
echo "direct=1" >> $TASK_FILE
echo "rw=${BENCH}" >> $TASK_FILE
echo "size=10G" >> $TASK_FILE
echo "time_based=1" >> $TASK_FILE
echo "runtime=${RUN_TIME}s" >> $TASK_FILE
echo "cpus_allowed=$CPUS" >> $TASK_FILE
echo "cpus_allowed_policy=shared" >> $TASK_FILE
#echo "group_reporting=1" >> $TASK_FILE

# Running LC tasks.
for i in `seq 0 $(expr $LC_NUM - 1)`
do
	${TASK_DIR}/fio_task.sh PREFIX=$BASE_NAME TASK_TYPE=LC INDEX=$i
done

# Running BE tasks.
for i in `seq 0 $(expr $BE_NUM - 1)`
do
	${TASK_DIR}/fio_task.sh PREFIX=$BASE_NAME TASK_TYPE=BE INDEX=$i NICE=10
done

time fio $TASK_FILE > /dev/null &
PID1=$!
time taskset -c 0 ${TASK_DIR}/comp.out &
PID2=$!
PID3=$(pgrep -P $PID2)
# Loop while the process exists
while kill -0 "$PID1" 2>/dev/null; do
    sleep 1
done
kill $PID3

echo "$BASE_NAME done."
