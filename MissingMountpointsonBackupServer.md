### Rsync Backup Script Failure: Missing Mountpoints on Backup Server

**Date:** 2026-04-04
**System:** `westmidlands2` (Ubuntu 24.04 backup server)

#### Summary

The rsync backup script `sync_eclipse_to_westmidlands2.sh` aborted with the error:

```
ERROR: /mnt/light not mounted on Westmidlands2
```

This occurred during the script’s initial safety checks before any rsync operations were executed.

#### Root Cause

The script verifies that the destination mountpoints `/mnt/light` and `/mnt/sound` exist as real mounted filesystems using `mountpoint -q`. These mountpoints are expected to correspond to local backup disks on `westmidlands2`.

At the time of execution:

* The drives expected at `/mnt/light` and `/mnt/sound` were **not visible to the operating system**.
* `lsblk`, `blkid`, and `findmnt` showed **no devices with the UUIDs referenced in `/etc/fstab`**.
* Because `/etc/fstab` used the `nofail` option, `mount -a` did not produce an error when the drives were absent.

As a result, the script correctly aborted to prevent rsync from writing into plain directories on the root filesystem.

#### Architecture Context

The backup workflow is structured as follows:

```
ECLIPSE-SERVER
    /mnt/light
    /mnt/sound
        │
        │ rsync over SSH
        ▼
WESTMIDLANDS2
    /mnt/light/eclipse_backup
    /mnt/sound/eclipse_backup
```

The directories `/mnt/light` and `/mnt/sound` on `westmidlands2` must therefore be **local backup disks**, not network shares.

#### Diagnosis Steps

The following commands confirmed the problem:

```
findmnt /mnt/light
findmnt /mnt/sound
lsblk -f
sudo blkid
```

These showed that the expected filesystems were missing entirely from the system.

#### Resolution

The backup disks were physically reconnected / power-cycled. Once Linux detected the drives again:

1. The devices appeared in `lsblk`.
2. `mount -a` mounted them according to `/etc/fstab`.
3. `findmnt /mnt/light` and `/mnt/sound` confirmed active mountpoints.
4. The rsync backup script ran normally.

#### Key Design Feature

The script intentionally aborts if the mountpoints are missing. This prevents a dangerous scenario where rsync would write backups into `/mnt/light` or `/mnt/sound` directories on the root filesystem if the actual disks were not mounted.

This safeguard worked as intended.

#### Lessons

* Always verify mountpoints before running destructive rsync operations.
* The `nofail` option in `/etc/fstab` prevents boot errors but can hide missing disks.
* Hardware issues (USB/SATA cables, enclosures, power) are common causes of disappearing backup drives.
* Monitoring tools like `lsblk` and `findmnt` are the fastest way to confirm mount status.
