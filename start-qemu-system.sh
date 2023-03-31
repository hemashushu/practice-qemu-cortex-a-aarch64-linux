#!/bin/bash
qemu-system-aarch64 -machine virt -cpu cortex-a76 -smp 4 -m 2G \
    -kernel build/vmlinuz-5.10.0-21-arm64 \
    -initrd build/initrd.img-5.10.0-21-arm64 \
    -append "root=/dev/vda2 console=ttyAMA0" \
    -drive if=none,file=build/hda.qcow2,format=qcow2,id=hd \
    -device virtio-blk-device,drive=hd \
    -netdev user,hostfwd=tcp::6422-:22,id=mynet \
    -device virtio-net-device,netdev=mynet \
    -nographic
