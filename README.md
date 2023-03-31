# QEMU Cortex-A AArch64 - Linux

Build a Cortex-A AArch64 development virtual machine with QEMU.

Machine config:

- machine: virt
- cpu: Cortex-A76 with 4 cores
- memory: 2GiB

https://www.qemu.org/docs/master/system/arm/virt.html

OS config:

Debian _arm64_, ARM 64 bit.

https://www.debian.org/distrib/netinst

- - -

Table of Content

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=4 orderedList=false} -->

<!-- code_chunk_output -->

- [Build the virtual machine](#-build-the-virtual-machine)
  - [Setup](#-setup)
  - [Boot into guest OS](#-boot-into-guest-os)
  - [Configuration after the first boot](#-configuration-after-the-first-boot)
  - [Login through SSH](#-login-through-ssh)
  - [Check your `sudo` privilegs](#-check-your-sudo-privilegs)
  - [Upgrade the kernel](#-upgrade-the-kernel)
- [Start of development](#-start-of-development)
  - [Write a `Hello World!` program](#-write-a-hello-world-program)
  - [Debug the program](#-debug-the-program)
  - [Step debugging into Glibc](#-step-debugging-into-glibc)

<!-- /code_chunk_output -->

## Build the virtual machine

### Setup

1. Create a new folder named "aarch64-debian" or any other name you like, and then enter this folder.

```bash
$ mkdir aarch64-debian
$ cd aarch64-debian
```

2. Download [linux](https://deb.debian.org/debian/dists/bullseye/main/installer-arm64/current/images/netboot/debian-installer/arm64/linux) and [initrd.gz](https://deb.debian.org/debian/dists/bullseye/main/installer-arm64/current/images/netboot/debian-installer/arm64/initrd.gz) from Debian web site.

```bash
$ wget https://deb.debian.org/debian/dists/bullseye/main/installer-arm64/current/images/netboot/debian-installer/arm64/linux
$ wget https://deb.debian.org/debian/dists/bullseye/main/installer-arm64/current/images/netboot/debian-installer/arm64/initrd.gz
```

**For information how to find these two files**

```text
1. https://www.debian.org/download
   click "Other Installers - Getting Debian"
2. https://www.debian.org/distrib
   click "Download an installation image - small installation image"
3. https://www.debian.org/distrib/netinst
   click "Network boot - arm64"
4. https://deb.debian.org/debian/dists/bullseye/main/installer-arm64/current/images/
   click "netboot/debian-installer/arm64/"
```

3. Create the `build` folder.

This folder will be used to store the hard disk image of the virtual machine and the kernel files.

```bash
$ mkdir build
```

Just create this folder, don't change into it.

4. Create a disk image.

Use the `QCOW2` as image file format. Since this virtual system will only install base softwares and development tools, 32GiB would be a resonable size.

```bash
$ qemu-img create -f qcow2 build/hda.qcow2 32G
```

5. Start the installer.

Here's how to install Debian.

Note that this system is for development only, not for our daily use, so it should be kept as simple as possible. Just use the default settings for most of the steps.

```bash
qemu-system-aarch64 -machine virt -cpu cortex-a76 -smp 4 -m 2G \
    -kernel linux \
    -initrd initrd.gz \
    -drive if=none,file=build/hda.qcow2,format=qcow2,id=hd \
    -device virtio-blk-device,drive=hd \
    -netdev user,id=mynet \
    -device virtio-net-device,netdev=mynet \
    -nographic \
    -no-reboot
```

Here are some key steps:

- Language: "English"
- Location: Select a location that matches your time zone, as the installation wizard does not provide a separate step for us to select a time zone.
- Keyboard: "American English"
- Hostname: "aarch64debian" or other name you like. Don't enter special characters, only [a-z], [0-9] and "-" (hyphen) are allowed.
- Domain name: "localdomain"
- Mirror: Select the mirror closest to your location.
- Proxy: Leave blank (means no proxy).
- Root password: Root user password, can be "123456" because it's easy to type, note this is a virtual machine and the password doesn't matter.
- New user full name: The display name of your new user, this user will be the default non-privileged user.
- New user login name: Can be the same as your host login name.
- New user password: New user password, can be "123456", it doesn't matter.

The following are the steps for partitioning:

- Partitioning method: "Guided - use entire disk"
- Select disk: "Virtual disk 1 (vda)"
- Partitioning scheme: "All files in one partition"
- Finish partitioning and write changes to disk.
- Write the changes to disks: "Yes"

Almost done:

- Statistics submission: "No"
- Choose software to install: **Only** select the "SSH Server" and "standard system utilities"
- Install the GRUB boot loader: This step will be failed, just ignore and continue.
- Installation complete: "Continue"

The QEMU program will exit because instead of reboot the virtual machine, because the parameter "-no-reboot" was added to QEMU.

6. Check the disk image.

```bash
$ ls -lh build
total 2.0G
-rw-r--r-- 1 yang yang 2.0G Mar 31 17:36 hda.qcow2
```

It seems to be Ok.

7. Copy the kernel files from the disk image out to the host filesystem.

Your need a tool called [libguestfs](https://libguestfs.org/), which you can install through your system's package manager.

Let's list the disk image:

```bash
$ virt-ls -v -a build/hda.qcow2 /boot
```

You may see quite a lot of output messages, scroll up slightly and you should see text looks like this:

```text
command: mount '-o' 'ro' '/dev/sda1' '/sysroot//boot'
guestfsd: => mount_ro (0x49) took 0.04 secs
guestfsd: <= ls0 (0x15b) request length 52 bytes
guestfsd: => ls0 (0x15b) took 0.00 secs
System.map-5.10.0-20-arm64
System.map-5.10.0-21-arm64
config-5.10.0-20-arm64
config-5.10.0-21-arm64
initrd.img
initrd.img-5.10.0-20-arm64
initrd.img-5.10.0-21-arm64
initrd.img.old
lost+found
vmlinuz
vmlinuz-5.10.0-20-arm64
vmlinuz-5.10.0-21-arm64
vmlinuz.old
libguestfs: closing guestfs handle 0x559f56e005c0 (state 2)
```

File `initrd.img-5.10.0-21-arm64` and `vmlinuz-5.10.0-21-arm64` are the files we need. Note that you may see different version number, just select the latest one.

Now copy them out to the host:

```bash
$ virt-copy-out -a build/hda.qcow2 /boot/initrd.img-5.10.0-21-arm64 build
$ virt-copy-out -a build/hda.qcow2 /boot/vmlinuz-5.10.0-21-arm64 build
```

Check again:

```bash
$ ls -lh build
total 2.1G
-rw-r--r-- 1 yang yang 2.0G Mar 31 17:36 hda.qcow2
-rw-r--r-- 1 yang yang  26M Mar 31 17:39 initrd.img-5.10.0-21-arm64
-rw-r--r-- 1 yang yang  27M Mar 31 17:39 vmlinuz-5.10.0-21-arm64
```

### Boot into guest OS

```bash
qemu-system-aarch64 -machine virt -cpu cortex-a76 -smp 4 -m 2G \
    -kernel build/vmlinuz-5.10.0-21-arm64 \
    -initrd build/initrd.img-5.10.0-21-arm64 \
    -append "root=/dev/vda2 console=ttyAMA0" \
    -drive if=none,file=build/hda.qcow2,format=qcow2,id=hd \
    -device virtio-blk-device,drive=hd \
    -netdev user,hostfwd=tcp::6422-:22,id=mynet \
    -device virtio-net-device,netdev=mynet \
    -nographic
```

You will see the login messgae if there is no exception:

```text
Debian GNU/Linux 11 aarch64debian ttyAMA0

aarch64debian login:
```

### Configuration after the first boot

After the first boot, there are some essential configurations that need to be done before it can become a normal development enviroment.

Login in as root user and install "sudo", "vim", "build-essential" and "gdb",  softwares:

```bash
# apt install sudo vim build-essential gdb
```

Add the default non-privileged user (which you create in the installation wizard) to "sudo" group:

```bash
# usermod -a -G sudo yang
```

Note that you need to replace "yang" above with your new non-privileged user name.

### Login through SSH

It's recommended to use our development environment by logging in to the virtual machine via SSH, as QEMU terminal sometimes has text display issue. Open another terminal window and run the following command:

```bash
$ ssh yang@localhost -p 6422
```

Replace "yang" above with your new non-privileged user name. The port `6422` is specified by the parameter `hostfwd=tcp::6422-:22` when you started QEMU, you can change it to another port. The purpose of this parameter is to redirect the host port `6422` to guest port `22`.

Once the login is successful, we can check the base hardware information of the virtual machine, such as memory, hard disk and CPU:

```bash
$ free -h
               total        used        free      shared  buff/cache   available
Mem:           1.9Gi        57Mi       1.8Gi       0.0Ki        67Mi       1.8Gi
Swap:          976Mi          0B       976Mi
```

```bash
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda2        30G  1.5G   27G   5% /
/dev/vda1       470M  106M  340M  24% /boot
...
```

```bash
$ cat /proc/cpuinfo
processor       : 0
BogoMIPS        : 125.00
Features        : fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp
CPU implementer : 0x41
CPU architecture: 8
CPU variant     : 0x4
CPU part        : 0xd0b
CPU revision    : 1
...
```

### Check your `sudo` privilegs

```bash
$ id
```

Make sure `groups=...27(sudo)...` is shown, now perform a privileged operation:

```bash
$ sudo apt update
```

If there is no exception, you may see the text:

```text
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
All packages are up to date.
```

Remember that even in a virtual machine, you should avoid using the root user directly.

> Use unprivileged user for most operations and use `sudo` command to promote permission only when privileged is needed, this rule always true in the Linux world.

### Upgrade the kernel

When you upgrade the guest OS and the kernel is updated, you will need to copy the new kernel from the guest OS out to the host filesystem. Which can be done by using `libguestfs` as described in the section above, but also by using `scp` utility.

## Start of development

### Write a `Hello World!` program

In the virtual machine, create a text file named `main.c`, and write the following text:

```c
#include <stdio.h>

int main(void)
{
    printf("Hello World!\n");
    return 0;
}
```

Try to compile it and run the output executable file:

```bash
$ gcc -g -Wall -o main.elf main.c
$ ./main.elf
```

When you see the output message "Hello World!", it indicates that our development enviroment has been setup successfully.

### Debug the program

Now try to debug the program via GDB:

```bash
$ gdb main.elf
```

Run some commands in the GDB interactive interface:

```gdb
(gdb) list
1       #include <stdio.h>
...
(gdb) start
...
Temporary breakpoint 1, main () at main.c:5
5           printf("Hello World!\n");
(gdb) n
Hello World!
6           return 0;
(gdb) n
7       }
```

Enter "q" to exit GDB, Everything is Ok.

### Step debugging into Glibc

Sometimes you may wonder how Glibc works, which requires debugging into Glibc. First you need to install `glibc-source` package, and then specify the source path of Glibc in GDB using the `set directories` command. here are the instructions:

First install `glibc-source` and extra the source tarball:

```bash
$ sudo apt install glibc-source
$ cd ~
$ tar xvf /usr/src/glibc/glibc-2.31.tar.xz
```

Create a new source file `args.c` so we can see how the variable number arguments `printf` function works.

```c
#include <stdio.h>

int main(void)
{
    printf("i=%d, j=%d\n", 0xaa, 0xbb);
    return 0;
}
```

Compile this file and debug it via GDB:

```bash
$ gcc -g -Wall -o args.elf args.c
$ gdb args.elf
```

Set the source path of Glibc in GDB:

```gdb
(gdb) show directories
Source directories searched: $cdir:$cwd
(gdb) set directories ~/glibc-2.31/
(gdb) show directories
Source directories searched: /home/yang/glibc-2.31:$cdir:$cwd
```

Step into Glibc by "s" command:

```gdb
(gdb) b main
Breakpoint 1 at 0x77c: file args.c, line 5.
(gdb) r
Starting program: /home/yang/temp/args.elf

Breakpoint 1, main () at args.c:5
5           printf("i=%d, j=%d\n", 0xaa,0xbb);
(gdb) s
__printf (format=0xaaaaaaaa0840 "i=%d, j=%d\n") at printf.c:28
28      {
(gdb) list
26      int
27      __printf (const char *format, ...)
28      {
29        va_list arg;
(gdb) n
32        va_start (arg, format);
(gdb) n
33        done = __vfprintf_internal (stdout, format, arg, 0);
(gdb) n
i=170, j=187
36        return done;
(gdb) n
main () at args.c:6
6           return 0;
```

As the above output shows, we can now step debugging into the `printf` function.
