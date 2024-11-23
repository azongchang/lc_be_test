#!/bin/bash

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

# Running LC tasks.
for i in `seq 0 $(expr $LC_NUM - 1)`
do
	${TASK_DIR}/fio_task.sh PREFIX=$BASE_NAME TASK_TYPE=LC INDEX=$i &
done

# Running BE tasks.
for i in `seq 0 $(expr $BE_NUM - 1)`
do
	${TASK_DIR}/fio_task.sh PREFIX=$BASE_NAME TASK_TYPE=BE INDEX=$i &
done

wait
echo "$BASE_NAME done."
