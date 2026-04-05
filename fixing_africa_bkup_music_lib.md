Here is a **concise Markdown summary** you can drop into your GitHub documentation repo describing what happened and how you restored the backup. I kept it short but technically clear.

---

```markdown
# Restoring MUSIC_LIB Backup (AfricaServer → westmidlands2)

## Summary

The automated rsync backup of `MUSIC_LIB` from **AfricaServer (Windows 11 + Cygwin)** to **westmidlands2 (Ubuntu)** stopped working due to a network IP address change.

The system uses:

- `rsync` over `ssh`
- Cygwin `cygsshd` on AfricaServer
- a pull-based backup script run on westmidlands2

The script expected AfricaServer at:

```

192.168.5.55

```

However, the **Eero router ignored the DHCP reservation** and assigned AfricaServer a new address:

```

192.168.4.96

```

As a result:

- `ping 192.168.5.55` failed
- `ssh` could not connect
- rsync backups failed

---

# Diagnosis

From `westmidlands2`:

```

ping 192.168.5.55

```

Result:

```

Destination Host Unreachable

```

Checking the IP on AfricaServer:

```

ipconfig

```

showed:

```

IPv4 Address : 192.168.4.96

```

---

# Verifying SSH Access

Tested from westmidlands2:

```

ssh rwillia@192.168.4.96

```

Login succeeded and opened a Cygwin shell.

Verified the music library path:

```

ls /cygdrive/m/MUSIC_LIB

```

---

# Verifying rsync Path

Tested rsync manually with a dry run:

```

rsync -rtvh --dry-run 
-e "ssh -i /home/royw/.ssh/id_ed25519" 
rwillia@192.168.4.96:/cygdrive/m/MUSIC_LIB/ 
/mnt/sound/backups/MUSIC_LIB_test/

```

Result:

```

593,859 files
~1.05 TB total data

```

This confirmed the backup pipeline works.

---

# Fix Applied

Updated the backup script host setting:

```

REMOTE_HOST="192.168.4.96"

```

or run with override:

```

./sync_musiclib_to_westmidlands2.sh --remote 192.168.4.96

```

---

# Running the Backup

Dry run (default):

```

./sync_musiclib_to_westmidlands2.sh --remote 192.168.4.96

```

Real backup:

```

./sync_musiclib_to_westmidlands2.sh --remote 192.168.4.96 --live

```

---

# Notes

- Cygwin does **not** need to be manually open on AfricaServer.
- The `cygsshd` service handles SSH connections.
- The failure was caused by **router DHCP behavior**, not rsync or Linux configuration.

---

# Recommendation

To prevent future failures:

- Ensure the router DHCP reservation for **AfricaServer** is stable.
- Consider referencing the host by name instead of IP if local DNS is reliable.

Example:

```

REMOTE_HOST="AFRICA-SERVER"

```

---

# Storage Notes

Backup destination:

```

/mnt/sound/backups/MUSIC_LIB

```

Available space at time of restoration:

```

~1.7 TB free

```

Backup size:

```

~1.05 TB

```
```

```

---

If you'd like, I can also help you write a **small “System Architecture” diagram for your GitHub repo** showing:

```

AfricaServer (Win11)
↓ ssh/rsync
westmidlands2 (Ubuntu backup server)
↓
/mnt/sound/backups

```

It makes future debugging **much easier when you revisit this system in a year.**
```
