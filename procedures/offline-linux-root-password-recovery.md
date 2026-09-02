# Offline Linux Root Password Recovery from an SD Card

## Purpose

This procedure documents how to recover or reset the `root` password of a Linux installation stored on an SD card by mounting that card from another working Linux system and using `chroot`.

It also documents how to inspect the offline operating system to determine which services are configured to start automatically on boot.

This method was validated on 2 September 2026 using:

- recovery host: `k3s-node-01`
- recovery host architecture: `aarch64`
- target media: `/dev/mmcblk0`
- target OS: CentOS Linux 7 (AltArch)
- target root filesystem: `/dev/mmcblk0p3`

The method changes the password in the offline operating system only. It does not change the root password of the recovery host.

## Preconditions

You must have:

- physical access to the SD card or block device containing the target OS;
- root or `sudo` access on a working Linux recovery host;
- a target Linux filesystem that can be mounted by the recovery host;
- compatible CPU architecture if you intend to execute binaries inside the target filesystem with `chroot`.

> **Warning:** Confirm the target device and partition before making any changes. Using the wrong filesystem can modify the recovery host or another attached disk.

## 1. Identify the target SD card

List the target block device and its partitions:

```bash
sudo fdisk -l
```

For the validated recovery, the SD card appeared as:

```text
/dev/mmcblk0       29.1G
/dev/mmcblk0p1      500M  FAT32
/dev/mmcblk0p2      512M  swap
/dev/mmcblk0p3      3.9G  Linux/ext4
```

Confirm filesystem types and existing mount points:

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS /dev/mmcblk0
```

Example validated output:

```text
NAME         SIZE FSTYPE MOUNTPOINTS
mmcblk0     29.1G
├─mmcblk0p1  500M vfat   /media/james/BE340262
├─mmcblk0p2  512M swap
└─mmcblk0p3  3.9G ext4   /media/james/83fb5392-803c-4387-a70e-a3d23b5d2c6c
```

In this example, the target root filesystem is already mounted at:

```text
/media/james/83fb5392-803c-4387-a70e-a3d23b5d2c6c
```

If the root filesystem is already mounted, do not mount it again.

## 2. Verify the target operating system

Set a variable for the mounted root filesystem:

```bash
SDROOT="/media/james/83fb5392-803c-4387-a70e-a3d23b5d2c6c"
```

Verify the operating system:

```bash
echo "===== SD CARD OS ====="
cat "$SDROOT/etc/os-release"

echo
echo "===== ROOT DIRECTORY ====="
ls -la "$SDROOT"
```

The validated SD card reported:

```text
NAME="CentOS Linux"
VERSION="7 (AltArch)"
ID="centos"
VERSION_ID="7"
PRETTY_NAME="CentOS Linux 7 (AltArch)"
```

The root directory should contain normal Linux paths such as:

```text
bin
boot
dev
etc
home
root
usr
var
```

Do not continue if the filesystem is not the intended OS installation.

## 3. Prepare the chroot environment

Bind the live kernel interfaces into the offline filesystem:

```bash
SDROOT="/media/james/83fb5392-803c-4387-a70e-a3d23b5d2c6c"

mount --bind /dev "$SDROOT/dev"
mount --bind /dev/pts "$SDROOT/dev/pts"
mount -t proc proc "$SDROOT/proc"
mount -t sysfs sys "$SDROOT/sys"
```

Enter the target operating system:

```bash
chroot "$SDROOT" /bin/bash
```

The prompt should now represent the target root environment, for example:

```text
[root@k3s-node-01 /]#
```

The hostname shown in the prompt is not sufficient evidence by itself that the correct filesystem is in use; the earlier `/etc/os-release` verification is the important safety check.

## 4. Reset the root password

Inside the chroot, run:

```bash
passwd root
```

Enter the new password twice when prompted.

CentOS 7 may display a password-quality warning such as:

```text
BAD PASSWORD: The password fails the dictionary check
```

A warning does not necessarily mean the password update failed. The successful completion message is:

```text
passwd: all authentication tokens updated successfully.
```

Use a strong, unique password even if the operating system permits a weaker one.

## 5. Verify the root account

While still inside the chroot, check the account state:

```bash
passwd -S root
```

The status should indicate that the root account has a password set. On CentOS/RHEL-family systems this commonly includes `PS`, depending on the `passwd` implementation.

## 6. Inspect what starts on boot

Because the target system is offline, `systemctl` cannot reliably report its live state. Instead, inspect the enablement symlinks stored in the target filesystem.

From the recovery host, run:

```bash
SDROOT="/media/james/83fb5392-803c-4387-a70e-a3d23b5d2c6c"

find "$SDROOT/etc/systemd/system" \
  -type l \
  -printf '%P -> %l\n' 2>/dev/null \
  | sort
```

The most useful boot targets are normally:

```text
multi-user.target.wants/
graphical.target.wants/
default.target.wants/
sockets.target.wants/
timers.target.wants/
```

To show only services explicitly enabled for normal multi-user boot:

```bash
find "$SDROOT/etc/systemd/system/multi-user.target.wants" \
  -maxdepth 1 \
  -type l \
  -printf '%f -> %l\n' 2>/dev/null \
  | sort
```

To list all enabled service units across the target filesystem:

```bash
find "$SDROOT/etc/systemd/system" \
  -type l \
  -name '*.service' \
  -printf '%P\n' 2>/dev/null \
  | sort
```

To inspect enabled timers and sockets as well:

```bash
echo "===== TIMERS ====="
find "$SDROOT/etc/systemd/system" \
  -type l \
  -name '*.timer' \
  -printf '%P -> %l\n' 2>/dev/null \
  | sort

echo
echo "===== SOCKETS ====="
find "$SDROOT/etc/systemd/system" \
  -type l \
  -name '*.socket' \
  -printf '%P -> %l\n' 2>/dev/null \
  | sort
```

CentOS 7 may also contain legacy SysV init services. Inspect those with:

```bash
find "$SDROOT/etc/rc.d" \
  -type l \
  -printf '%P -> %l\n' 2>/dev/null \
  | sort
```

For a concise boot inventory, use:

```bash
SDROOT="/media/james/83fb5392-803c-4387-a70e-a3d23b5d2c6c"

for TARGET in \
  multi-user.target.wants \
  graphical.target.wants \
  default.target.wants \
  timers.target.wants \
  sockets.target.wants
do
  DIR="$SDROOT/etc/systemd/system/$TARGET"
  [ -d "$DIR" ] || continue
  echo
  echo "===== $TARGET ====="
  find "$DIR" -maxdepth 1 -type l -printf '%f -> %l\n' | sort
done
```

This reports what is configured to start or activate at boot. It does not prove that each unit successfully starts; that can only be validated by booting the target OS and checking its runtime state and logs.

## 7. Optional installed-package inventory

To determine what software is installed on the offline CentOS system:

```bash
chroot "$SDROOT" /bin/rpm -qa \
  --qf '%{NAME}\t%{VERSION}-%{RELEASE}\t%{ARCH}\n' \
  | sort
```

For a concise list of commonly interesting server packages:

```bash
chroot "$SDROOT" rpm -qa | sort | grep -Ei \
'httpd|apache|nginx|mysql|maria|postgres|php|python|java|tomcat|docker|kube|samba|nfs|ssh|snmp|zabbix|nagios|puppet|ansible|rsync|ftp|bind|dns|dhcp|firewalld|iptables'
```

## 8. Leave the chroot

If still inside the target OS, exit it:

```bash
exit
```

You should now be back in the recovery host shell.

## 9. Remove the temporary chroot mounts

Set the root path again if necessary:

```bash
SDROOT="/media/james/83fb5392-803c-4387-a70e-a3d23b5d2c6c"
```

Unmount in reverse dependency order:

```bash
umount "$SDROOT/dev/pts"
umount "$SDROOT/dev"
umount "$SDROOT/proc"
umount "$SDROOT/sys"
```

Check that no temporary chroot mounts remain:

```bash
mount | grep "$SDROOT"
```

At this stage it is normal for the SD-card root filesystem itself still to be mounted by the desktop or automounter.

## Validation record

Validated successfully on `k3s-node-01` on 2 September 2026 against a CentOS Linux 7 AltArch SD-card installation.

Observed successful password-reset result:

```text
passwd: all authentication tokens updated successfully.
```

## Notes

- Direct root SSH login is controlled separately by SSH configuration and is not automatically enabled by changing the root password.
- Do not expose or record the recovered password in this repository.
- Always inspect `/etc/os-release` before entering the chroot so that the target filesystem is positively identified.
- A service being enabled does not guarantee that it starts successfully; boot-time runtime validation is a separate step.
