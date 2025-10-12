Here’s a tidy README-style summary you can drop into GitHub alongside the script.

Westmidlands2 ⇐ Eclipse Backup (rsync over SSH)

This script runs on Westmidlands2 (cold backup server) and pulls media from eclipse-server (hot/live).
It mirrors:

eclipse-server:/mnt/light/ → westmidlands2:/mnt/light/eclipse_backup/

eclipse-server:/mnt/sound/ → westmidlands2:/mnt/sound/eclipse_backup/

Deletions happen only on Westmidlands2 (the destination) so the cold backup matches the live source.

What the script does (in plain English)

Verifies destination mount points and directories on Westmidlands2.

Verifies the remote source paths on eclipse are present and non-empty (guard against empty/missing mounts).

Runs an rsync dry-run first and shows what would change.

Waits for you to type yes before the real sync (unless AUTO_YES=true).

Syncs content only by default (ignores owners/ACLs/xattrs — perfect for media libraries).

Excludes obvious noise and prevents self-copy loops:

Excludes /L_backup/***, /S_backup/***, /eclipse_backup/***, lost+found/, .DS_Store, etc.

Protects lost+found/ on the destination.

Logs everything to ~/logs/rsync_eclipse_<timestamp>.log.

Prerequisites

On Westmidlands2, create an SSH key and install it on Eclipse:

ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_eclipse_to_westmidlands2 -C "westmidlands2→eclipse"
ssh-copy-id -i ~/.ssh/id_ed25519_eclipse_to_westmidlands2.pub rwillia@eclipse-server
ssh -i ~/.ssh/id_ed25519_eclipse_to_westmidlands2 rwillia@eclipse-server 'echo OK'


Add a tiny SSH config on Westmidlands2:

mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat >> ~/.ssh/config <<'EOF'
Host eclipse-server
    HostName eclipse-server
    User rwillia
    IdentityFile ~/.ssh/id_ed25519_eclipse_to_westmidlands2
EOF
chmod 600 ~/.ssh/config


Ensure the destination directories exist and are writable by your user:

sudo install -d -o "$USER" -g "$USER" -m 0755 /mnt/light/eclipse_backup /mnt/sound/eclipse_backup
# If they already exist but are root-owned:
# sudo chown -R "$USER:$USER" /mnt/light/eclipse_backup /mnt/sound/eclipse_backup

How to run

Put the script on Westmidlands2, make it executable:

chmod +x ~/Desktop/sync_eclipse_to_westmidlands2.sh


Run it (it will dry-run first, then prompt):

~/Desktop/sync_eclipse_to_westmidlands2.sh
# Look over the DRY RUN.
# When asked:
#   Proceed with REAL RUN for 'LIGHT → eclipse_backup'? Type 'yes' to continue:
# type: yes


(Optional) Non-interactive mode once you trust it:

AUTO_YES=true ~/Desktop/sync_eclipse_to_westmidlands2.sh


(Optional) Full metadata mode (owners/ACLs/xattrs):

Set PRESERVE_METADATA="true" inside the script and run rsync with local sudo, plus allow sudo rsync on Eclipse (via --rsync-path="sudo rsync"). For media, the default content-only mode is typically best.

Verify results

Fast check (counts what would still change):

rsync -avhn --delete --info=stats2 \
  --exclude '/L_backup/***' --exclude '/S_backup/***' --exclude '/eclipse_backup/***' \
  eclipse-server:/mnt/light/  /mnt/light/eclipse_backup/
rsync -avhn --delete --info=stats2 \
  --exclude '/L_backup/***' --exclude '/S_backup/***' --exclude '/eclipse_backup/***' \
  eclipse-server:/mnt/sound/  /mnt/sound/eclipse_backup/
# If "Number of regular files transferred: 0", they match.


Spot-check sizes:

du -sh /mnt/light/eclipse_backup /mnt/sound/eclipse_backup
ssh eclipse-server 'du -sh /mnt/light /mnt/sound'


(Optional) Path-only difference list:

ssh eclipse-server 'cd /mnt/light && find . -type f -printf "%P\n" | sort' > light_src.txt
cd /mnt/light/eclipse_backup && find . -type f -printf "%P\n" | sort > light_dst.txt
diff --brief light_src.txt light_dst.txt | wc -l

Safety notes

Run this on Westmidlands2. It pulls from Eclipse over SSH.

Deletions occur only on Westmidlands2 to mirror the live source.

Script refuses to run if the remote source paths are missing/empty (prevents syncing “nothing”).

Dry-run gate ensures you see changes before anything is modified.

lost+found/ on the destination is protected and not touched.

Common issues & fixes

Permission denied writing into /mnt/*/eclipse_backup
→ Set ownership to your user (see prerequisites step 3) or run the rsync step as root locally.

Rsync exit code 23/24 on dry-run
→ Usually “vanished files” or protected dirs; the script tolerates these and still prompts for the real run.

Nested eclipse_backup inside the destination
→ The script excludes /eclipse_backup/*** and will clean any previously nested copies during the first run.
