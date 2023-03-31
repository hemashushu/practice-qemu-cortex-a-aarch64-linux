#!/bin/bash
qemu-system-aarch64 -machine virt -cpu cortex-a76 -smp 4 -m 2G \
    -kernel linux \
    -initrd initrd.gz \
    -drive if=none,file=build/hda.qcow2,format=qcow2,id=hd \
    -device virtio-blk-device,drive=hd \
    -netdev user,id=mynet \
    -device virtio-net-device,netdev=mynet \
    -nographic \
    -no-reboot
