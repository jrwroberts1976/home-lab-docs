# Offline Linux Root Password Recovery from an SD Card

## Purpose

Recover or reset the `root` password of a Linux installation stored on an SD card by mounting the card from another Linux system and using `chroot`.

The commands below also show how to inventory installed packages and identify services configured to start automatically on boot.

> Confirm the target device and root partition before making any changes.

## 1. Identify the SD card and root filesystem

```bash
sudo fdisk -l
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS /dev/mmcblk0
```

If the target root filesystem is already mounted, use its existing mount point. Otherwise mount it manually.

```bash
sudo mkdir -p /mnt/sdroot
sudo mount /dev/mmcblk0p3 /mnt/sdroot
SDROOT="/mnt/sdroot"
```

If it is already mounted elsewhere, set `SDROOT` to that path instead:

```bash
SDROOT="/path/to/mounted/root/filesystem"
```

## 2. Verify the target OS

```bash
cat "$SDROOT/etc/os-release"
ls -la "$SDROOT"
```

## 3. Prepare the chroot

Run as root or prefix the commands with `sudo`.

```bash
mount --bind /dev "$SDROOT/dev"
mount --bind /dev/pts "$SDROOT/dev/pts"
mount -t proc proc "$SDROOT/proc"
mount -t sysfs sys "$SDROOT/sys"
```

## 4. Enter the target OS

```bash
chroot "$SDROOT" /bin/bash
```

## 5. Reset the root password

```bash
passwd root
```

## 6. Verify the root account

```bash
passwd -S root
```

## 7. Exit the chroot

```bash
exit
```

## 8. Inspect what starts automatically on boot

List all systemd enablement links:

```bash
find "$SDROOT/etc/systemd/system" \
  -type l \
  -printf '%P -> %l\n' 2>/dev/null \
  | sort
```

List services enabled for normal multi-user boot:

```bash
find "$SDROOT/etc/systemd/system/multi-user.target.wants" \
  -maxdepth 1 \
  -type l \
  -printf '%f -> %l\n' 2>/dev/null \
  | sort
```

List all enabled systemd services:

```bash
find "$SDROOT/etc/systemd/system" \
  -type l \
  -name '*.service' \
  -printf '%P -> %l\n' 2>/dev/null \
  | sort
```

List enabled timers:

```bash
find "$SDROOT/etc/systemd/system" \
  -type l \
  -name '*.timer' \
  -printf '%P -> %l\n' 2>/dev/null \
  | sort
```

List enabled sockets:

```bash
find "$SDROOT/etc/systemd/system" \
  -type l \
  -name '*.socket' \
  -printf '%P -> %l\n' 2>/dev/null \
  | sort
```

Check legacy SysV boot links:

```bash
find "$SDROOT/etc/rc.d" \
  -type l \
  -printf '%P -> %l\n' 2>/dev/null \
  | sort
```

Combined boot inventory:

```bash
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

## 9. Inventory installed software

List all installed RPM packages:

```bash
chroot "$SDROOT" /bin/rpm -qa \
  --qf '%{NAME}\t%{VERSION}-%{RELEASE}\t%{ARCH}\n' \
  | sort
```

Count installed packages:

```bash
chroot "$SDROOT" rpm -qa | wc -l
```

Show commonly interesting server packages:

```bash
chroot "$SDROOT" rpm -qa | sort | grep -Ei \
'httpd|apache|nginx|mysql|maria|postgres|php|python|java|tomcat|docker|kube|samba|nfs|ssh|snmp|zabbix|nagios|puppet|ansible|rsync|ftp|bind|dns|dhcp|firewalld|iptables'
```

## 10. Clean up temporary chroot mounts

```bash
umount "$SDROOT/dev/pts"
umount "$SDROOT/dev"
umount "$SDROOT/proc"
umount "$SDROOT/sys"
```

Verify the temporary mounts are gone:

```bash
mount | grep "$SDROOT"
```

If the root filesystem was mounted manually for recovery, unmount it when finished:

```bash
umount "$SDROOT"
```

## Notes

- Changing the root password does not automatically enable direct root SSH login.
- Do not store the recovered password in Git.
- Always verify `/etc/os-release` before entering the chroot.
- Boot-enablement links show what is configured to start; they do not prove that each service starts successfully.
