#!/bin/bash

time taskset -c 0 tasks/comp.out &
pid=$!

