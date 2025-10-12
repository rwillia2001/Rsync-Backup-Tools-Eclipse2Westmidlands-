#!/usr/bin/env bash
# =====================================================================
#  sync_eclipse_to_westmidlands2.sh
#  RUN FROM: Westmidlands2 (cold backup)
#  PULLS FROM: eclipse-server:/mnt/light and /mnt/sound (hot/live)
#  DESTS: /mnt/light/eclipse_backup and /mnt/sound/eclipse_backup
#  Deletions occur ONLY on Westmidlands2 to mirror Eclipse.
# =====================================================================

set -euo pipefail

REMOTE_HOST="eclipse-server"   # uses ~/.ssh/config
SRC_LIGHT="/mnt/light/"
SRC_SOUND="/mnt/sound/"
DST_LIGHT="/mnt/light/eclipse_backup/"
DST_SOUND="/mnt/sound/eclipse_backup/"
LOG_DIR="$HOME/logs"; mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/rsync_eclipse_$(date +%F_%H-%M-%S).log"

# Content-only backup (simple & safe for media)
COMMON_OPTS=(
  -avh
  --delete
  --delete-delay
  --delete-excluded
  --info=progress2
  --partial
  --inplace
  --protect-args

  # PROTECT dest filesystem dir so it is never touched
  --filter 'P lost+found/'

  # EXCLUDES on the source side (and remove any already-mirrored copies in dest)
  --exclude '/L_backup/***'
  --exclude '/S_backup/***'
  --exclude '/eclipse_backup/***'

  # OS cruft
  --exclude '.DS_Store'
  --exclude 'Thumbs.db'
  --exclude '.Trash-*/'
  --exclude '.nfs*'

  # Content-only metadata (simple & robust for media)
  --no-owner --no-group --no-acls --no-xattrs --omit-dir-times
)


abort(){ echo -e "\nERROR: $*\n" | tee -a "$LOG"; exit 1; }
check_mountpoint(){ mountpoint -q "$1" || abort "$1 not mounted on Westmidlands2"; }
check_local_dest(){ [[ -d "$1" ]] || abort "Destination missing: $1"; }
check_remote_src(){
  ssh "$REMOTE_HOST" "test -d '$1' && [ \"\$(ls -A '$1')\" ]" \
    || abort "Remote source missing/empty on $REMOTE_HOST: $1"
}

run_rsync(){
  local label="$1" remote_path="$2" local_dest="$3"

  echo -e "\n--- DRY RUN: $label ---" | tee -a "$LOG"

  # Allow rsync dry-run to return 23/24 without killing the script
  set +e
  rsync "${COMMON_OPTS[@]}" --dry-run "${REMOTE_HOST}:${remote_path}" "${local_dest}" |& tee -a "$LOG"
  rc_dry=${PIPESTATUS[0]}
  set -e

  if [[ $rc_dry -ne 0 && $rc_dry -ne 23 && $rc_dry -ne 24 ]]; then
    abort "Dry run failed with rsync exit code $rc_dry"
  fi

  if [[ "${AUTO_YES:-false}" != "true" ]]; then
    read -r -p "Proceed with REAL RUN for '$label'? Type 'yes' to continue: " OK
    [[ "$OK" == "yes" ]] || abort "Aborted by user."
  fi

  echo -e "\n--- REAL RUN: $label ---" | tee -a "$LOG"

  # Real run: also tolerate 23/24 (vanished files, attrs) unless you want to be stricter
  set +e
  rsync "${COMMON_OPTS[@]}" "${REMOTE_HOST}:${remote_path}" "${local_dest}" |& tee -a "$LOG"
  rc_real=${PIPESTATUS[0]}
  set -e

  if [[ $rc_real -ne 0 && $rc_real -ne 23 && $rc_real -ne 24 ]]; then
    abort "Real run failed with rsync exit code $rc_real"
  fi
}


echo "=== $(date) START sync from $REMOTE_HOST ===" | tee -a "$LOG"

check_mountpoint "/mnt/light"
check_mountpoint "/mnt/sound"
check_local_dest "$DST_LIGHT"
check_local_dest "$DST_SOUND"
check_remote_src "$SRC_LIGHT"
check_remote_src "$SRC_SOUND"

echo "
REMOTE (source)  : ${REMOTE_HOST}:${SRC_LIGHT}  and  ${SRC_SOUND}
LOCAL  (dest)    : ${DST_LIGHT}  and  ${DST_SOUND}
Log file         : ${LOG}
" | tee -a "$LOG"

run_rsync "LIGHT → eclipse_backup" "$SRC_LIGHT" "$DST_LIGHT"
run_rsync "SOUND → eclipse_backup" "$SRC_SOUND" "$DST_SOUND"

echo -e "\n=== $(date) DONE ===" | tee -a "$LOG"
