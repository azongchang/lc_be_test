#!/bin/bash

TEST_DIR=/mnt/nvme
TASK_DIR=./tasks

echo "Tesing 1 default LC task and 1 default BE task."
rm -r ${TEST_DIR}/* 2> /dev/null
mkdir ${TEST_DIR}/task0
mkdir ${TEST_DIR}/task1

BASE_NAME=$(basename "$0" .sh)
${TASK_DIR}/fio_task.sh PREFIX=$BASE_NAME TASK_TYPE=LC INDEX=0 &
${TASK_DIR}/fio_task.sh PREFIX=$BASE_NAME TASK_TYPE=BE INDEX=1 &

wait
echo "Done."
