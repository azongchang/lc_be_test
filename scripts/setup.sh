#!/bin/bash

if [[ "$1" = "reset" ]]; then
	rm -r /mnt/nvme/* 2> /dev/null
	umount /mnt/nvme
	rmdir /mnt/nvme
	exit 0
fi

mkdir -p /mnt/nvme
mount /dev/nvme0n1 /mnt/nvme

