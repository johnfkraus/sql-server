#!/usr/bin/env bash
#
# migrate.sh — one-step migration of multiple databases between two
# SQL Server instances running as Podman containers (same Podman host).
#
# For each database it:
#   1. Runs BACKUP DATABASE on the source container (WITH CHECKSUM).
#   2. Streams the .bak through the host into the target container.
#   3. Reads RESTORE FILELISTONLY and builds MOVE clauses automatically,
#      so logical file names never have to be hard-coded.
#   4. Drops any existing copy on the target, restores, and verifies.
#
# The run is idempotent: re-running it simply replaces the target
# databases with fresh copies.
#
# Usage:
#   ./migrate.sh [config-file]        # default: ./config.env
#   DRY_RUN=true ./migrate.sh         # preview only
#
set -eo pipefail

CONFIG_FILE="${1:-config.env}"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[error] config file '$CONFIG_FILE' not found" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG_FILE"

: "${SOURCE_CONTAINER:?must be set in $CONFIG_FILE}"
: "${SOURCE_SA_PASSWORD:?must be set in $CONFIG_FILE}"
: "${TARGET_CONTAINER:?must be set in $CONFIG_FILE}"
: "${TARGET_SA_PASSWORD:?must be set in $CONFIG_FILE}"
: "${DATABASES:?must be set in $CONFIG_FILE}"
BACKUP_DIR="${BACKUP_DIR:-/var/opt/mssql/backup}"
STAGING_DIR="${STAGING_DIR:-./staging}"
DRY_RUN="${DRY_RUN:-false}"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

command -v podman >/dev/null || die "podman not found on PATH"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Locate sqlcmd inside a container (tools18 in newer images, tools17 in older).
find_sqlcmd() {
  local container="$1" path
  for path in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
    if podman exec "$container" bash -c "test -x $path" 2>/dev/null; then
      echo "$path"
      return 0
    fi
  done
  return 1
}

# Run sqlcmd as sa inside a container.
# The password is passed via the SQLCMDPASSWORD environment variable so it
# never appears on a command line (invisible to `ps`).
# Set DRY_RUN_BYPASS=1 (as a prefix) to force execution even in dry-run mode.
run_sql() {
  local container="$1" sqlcmd="$2" password="$3"
  shift 3
  local flags=()
  if [[ "$sqlcmd" == *tools18* ]]; then
    flags+=(-C)  # trust the container's self-signed TLS certificate
  fi
  if [[ "$DRY_RUN" == true && "${DRY_RUN_BYPASS:-0}" != 1 ]]; then
    printf '[dry-run] podman exec %s %s %s\n' "$container" "$(basename "$sqlcmd")" "$*"
    return 0
  fi
  podman exec --env "SQLCMDPASSWORD=$password" "$container" \
    "$sqlcmd" -b -S localhost -U sa "${flags[@]}" "$@"
}

# Sanitize a logical file name for use inside a physical file name.
sanitize() { printf '%s' "$1" | tr -c 'A-Za-z0-9_-' '_'; }

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------

log "checking containers and locating sqlcmd"
SRC_SQLCMD="$(find_sqlcmd "$SOURCE_CONTAINER")" || die "sqlcmd not found inside $SOURCE_CONTAINER"
DST_SQLCMD="$(find_sqlcmd "$TARGET_CONTAINER")" || die "sqlcmd not found inside $TARGET_CONTAINER"

mkdir -p "$STAGING_DIR"
podman exec "$SOURCE_CONTAINER" mkdir -p "$BACKUP_DIR"
podman exec "$TARGET_CONTAINER" mkdir -p "$BACKUP_DIR"

# Default data directory on the target (e.g. /var/opt/mssql/data/)
TARGET_DATA_DIR="$(DRY_RUN_BYPASS=1 run_sql "$TARGET_CONTAINER" "$DST_SQLCMD" "$TARGET_SA_PASSWORD" \
  -W -h -1 -Q "SET NOCOUNT ON; SELECT CONVERT(nvarchar(400), SERVERPROPERTY('InstanceDefaultDataPath'))" \
  | tr -d '\r\n' | sed 's/ *$//')"
TARGET_DATA_DIR="${TARGET_DATA_DIR%/}/"
log "target data directory: $TARGET_DATA_DIR"

# ---------------------------------------------------------------------------
# Per-database migration
# ---------------------------------------------------------------------------

migrate_db() {
  local db="$1"
  local bak="$BACKUP_DIR/$db.bak"

  log "[$db] backing up on $SOURCE_CONTAINER"
  run_sql "$SOURCE_CONTAINER" "$SRC_SQLCMD" "$SOURCE_SA_PASSWORD" \
    -Q "BACKUP DATABASE [$db] TO DISK='$bak' WITH INIT, CHECKSUM, STATS=5" || return 1

  if [[ "$DRY_RUN" == true ]]; then
    log "[$db] (dry run) would copy the backup to $TARGET_CONTAINER and restore it with MOVE clauses computed from RESTORE FILELISTONLY"
    return 0
  fi

  log "[$db] streaming backup: $SOURCE_CONTAINER -> host -> $TARGET_CONTAINER"
  podman exec "$SOURCE_CONTAINER" cat "$bak" > "$STAGING_DIR/$db.bak" || return 1
  podman exec -i "$TARGET_CONTAINER" bash -c "cat > '$bak'" < "$STAGING_DIR/$db.bak" || return 1

  # Read the backup's file list and build MOVE clauses with collision-free names.
  local moves=() logical physical ftype rest ext safe logical_esc
  while IFS='|' read -r logical physical ftype rest; do
    [[ -z "${logical//[[:space:]]/}" ]] && continue
    case "$ftype" in
      D) ext=mdf ;;
      L) ext=ldf ;;
      *) warn "[$db] file '$logical' has type '$ftype' — not restored (only data/log files are handled)"; continue ;;
    esac
    logical_esc="${logical//\'/\'\'}"
    safe="$(sanitize "$logical")"
    moves+=("MOVE '$logical_esc' TO '$TARGET_DATA_DIR${db}_$safe.$ext'")
  done < <(DRY_RUN_BYPASS=1 run_sql "$TARGET_CONTAINER" "$DST_SQLCMD" "$TARGET_SA_PASSWORD" \
             -W -s '|' -Q "SET NOCOUNT ON; RESTORE FILELISTONLY FROM DISK='$bak'" \
             | tail -n +3 | tr -d '\r')
  if [[ "${#moves[@]}" -eq 0 ]]; then
    warn "[$db] could not read the backup file list — skipping"
    return 1
  fi

  log "[$db] dropping any existing copy of [$db] on $TARGET_CONTAINER (idempotent)"
  run_sql "$TARGET_CONTAINER" "$DST_SQLCMD" "$TARGET_SA_PASSWORD" \
    -Q "IF DB_ID(N'$db') IS NOT NULL BEGIN ALTER DATABASE [$db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db]; END" || return 1

  local moves_str
  moves_str="$(IFS=','; echo "${moves[*]}")"
  log "[$db] restoring on $TARGET_CONTAINER"
  run_sql "$TARGET_CONTAINER" "$DST_SQLCMD" "$TARGET_SA_PASSWORD" \
    -Q "RESTORE DATABASE [$db] FROM DISK='$bak' WITH RECOVERY, CHECKSUM, REPLACE, STATS=5, $moves_str" || return 1

  log "[$db] verifying"
  run_sql "$TARGET_CONTAINER" "$DST_SQLCMD" "$TARGET_SA_PASSWORD" \
    -W -Q "SET NOCOUNT ON; SELECT name + ' -> ' + state_desc FROM sys.databases WHERE name = N'$db'"
}

ok=0
failed=0
for db in "${DATABASES[@]}"; do
  if migrate_db "$db"; then
    ok=$((ok + 1))
    log "[$db] done"
  else
    failed=$((failed + 1))
    warn "[$db] FAILED — continuing with remaining databases"
  fi
done

echo
suffix=""
[[ "$DRY_RUN" == true ]] && suffix=" (dry run)"
log "summary: $ok succeeded, $failed failed, ${#DATABASES[@]} total$suffix"
[[ "$failed" -eq 0 ]] || exit 1
