Below is a **clean Markdown document** you can drop directly into your GitHub documentation repo (for example: `westmidlands2_storage.md`).
I included:

* physical drive mapping
* partitions
* filesystem types
* mount points
* troubleshooting notes
* hot-swap bay issue explanation
* useful diagnostic commands

You can of course update sizes later if drives change.

---

# Westmidlands2 Storage Layout and Notes

## Overview

`westmidlands2` is a Linux (Ubuntu 24.04) server used primarily for:

* backup storage
* rsync targets
* UrBackup repository
* media storage

The system contains several internal drives mounted under `/mnt`.

The system root OS is installed on an NVMe drive.

---

# Physical Drive Layout

| Bay   | Drive       | Size  | Purpose                    |
| ----- | ----------- | ----- | -------------------------- |
| Bay 1 | WD Red      | 4 TB  | AV media storage           |
| Bay 2 | Toshiba HDD | 14 TB | Light storage / large data |
| Bay 3 | WD Red      | 2 TB  | Backup / UrBackup storage  |

These drives are installed in a **hot-swap cage** inside the chassis.

---

# Filesystem Layout

Current mounted filesystems (`df -h`):

| Mount Point     | Device           | Size | Used | Available | Filesystem |
| --------------- | ---------------- | ---- | ---- | --------- | ---------- |
| `/`             | `/dev/nvme0n1p2` | 1.8T | 31G  | 1.7T      | ext4       |
| `/boot/efi`     | `/dev/nvme0n1p1` | 1.1G | 6.2M | 1.1G      | FAT32      |
| `/mnt/av_media` | `/dev/sda2`      | 3.7T | 3.4T | 289G      | ext4       |
| `/mnt/sound`    | `/dev/sdb2`      | 3.2T | 1.3T | 1.7T      | ext4       |
| `/mnt/light`    | `/dev/sdb1`      | 9.5T | 5.3T | 3.8T      | ext4       |
| `/mnt/xfsdata`  | `/dev/sdc1`      | 1.9T | 1.6T | 261G      | xfs        |

---

# Drive / Partition Mapping

## Bay 1 – 4TB WD Red

Device:

```
/dev/sda
```

Partition layout:

```
/dev/sda2
```

Mount point:

```
/mnt/av_media
```

Filesystem:

```
ext4
```

Usage:

* AV media
* archived video/photo data

---

## Bay 2 – 14TB Toshiba HDD

Device:

```
/dev/sdb
```

Partitions:

```
/dev/sdb1 → /mnt/light
/dev/sdb2 → /mnt/sound
```

Filesystem:

```
ext4
```

Usage:

`/mnt/light`

* large archive storage
* media

`/mnt/sound`

* audio related storage
* media libraries

---

## Bay 3 – 2TB WD Red

Device:

```
/dev/sdc
```

Partition:

```
/dev/sdc1
```

Mount point:

```
/mnt/xfsdata
```

Filesystem:

```
xfs
```

Usage:

* UrBackup storage
* backup repository

---

# Root System Drive

NVMe SSD:

```
/dev/nvme0n1
```

Partitions:

```
/dev/nvme0n1p1 → EFI
/dev/nvme0n1p2 → root filesystem
```

Filesystem:

```
ext4
```

Mount points:

```
/
/boot/efi
```

---

# Known Hardware Issue – Hot-Swap Bay Seating

## Problem

The hot-swap drive cage requires drives to be **fully seated into the backplane connectors**.

If a drive is not pushed completely into the SATA backplane:

* the drive may appear/disappear
* mount points may fail
* filesystem may not appear
* intermittent SATA disconnects can occur

Symptoms observed:

* drives missing from `lsblk`
* mount failures
* storage temporarily disappearing

## Root Cause

The drive trays must be pushed **firmly to the rear of the bay** so the SATA power and data connectors mate properly.

The final **3–5 mm of insertion requires noticeable force**.

The tray may feel fully inserted before the connector actually engages.

## Correct Insertion Method

1. Slide the drive tray into the rails.
2. Push until resistance is felt.
3. Push firmly straight back.
4. Ensure the tray cannot move forward.

If the tray can move forward slightly, it is **not fully seated**.

---

# Diagnostic Commands

Useful commands when diagnosing drive issues.

## List block devices

```
lsblk -f
```

---

## View mounted filesystems

```
df -h
```

---

## Check kernel drive messages

```
dmesg | tail -100
```

Look for:

```
SATA link down
I/O error
device reset
```

---

## Detect recent disk errors

```
dmesg | grep -i error
```

---

## Check drive SMART health

```
sudo smartctl -a /dev/sdX
```

Example:

```
sudo smartctl -a /dev/sda
```

---

# Storage Utilization Notes

Current space usage:

| Mount           | Used | Free | Status    |
| --------------- | ---- | ---- | --------- |
| `/mnt/av_media` | 93%  | 289G | Near full |
| `/mnt/sound`    | 43%  | 1.7T | Healthy   |
| `/mnt/light`    | 59%  | 3.8T | Healthy   |
| `/mnt/xfsdata`  | 87%  | 261G | Monitor   |

Recommendation:

Keep filesystems below **90% utilization** to avoid fragmentation and performance degradation.

---

# Useful Tools

### Disk usage explorer

```
ncdu
```

Install:

```
sudo apt install ncdu
```

Example:

```
sudo ncdu /mnt/av_media
```

---

# Maintenance Checklist

Occasional checks recommended:

```
df -h
lsblk
dmesg | grep -i sata
dmesg | grep -i error
```

Verify:

* drives are visible
* mount points exist
* no SATA errors reported

---

# Notes

This server acts as a **storage backend for backup and media systems**, including:

* rsync backups
* UrBackup repository
* media archives

Reliability of the hot-swap bay seating is critical to maintain stable disk connections.

---

If you'd like, I can also help you add **two extremely useful sections** that most home-lab GitHub repos include:

1. **Full disk topology diagram (very helpful later)**
2. **fstab documentation** so you always know exactly how drives mount on boot.

Both make future troubleshooting **much easier**.
