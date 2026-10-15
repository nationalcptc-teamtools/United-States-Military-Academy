#!/usr/bin/env bash
# CPTC end-of-session activity log collector
#
# Run this when you are finished working on a box.  It gathers the operator
# activity trail that `cptc-linux.sh logging enable` set up, plus any run
# directories produced by the enumeration runner, and writes a single zip
# archive to your Desktop.
#
# This collects OUR OWN activity record, for the client report and for
# competition deconfliction.  The archive can contain target output and
# anything typed into a terminal, so it is written mode 0600 and should be
# handled as engagement-sensitive material.
#
# Design notes earned the hard way:
#  - Under sudo, $HOME is root's home.  The Desktop is resolved from the
#    invoking operator's passwd entry and XDG_DESKTOP_DIR, never from $HOME.
#  - Configuration state lies about auditd: rules can be loaded into a
#    subsystem that is switched off.  The manifest records what the audit
#    subsystem actually reported, not just that rules existed.
#  - zip exits 18 when it could not read some input yet still writes a valid
#    archive.  That is treated as partial success and recorded, not as failure.
#  - Nothing is silently dropped.  Every skip and every truncation is written
#    into the manifest with a reason.

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly AUDIT_KEY="cptc-exec"

MAX_FILE_MB=256
INCLUDE_SUDO_IO=1
OUTPUT_DIR=""
STAGE=""
ARCHIVE_PATH=""
declare -a RUN_DIRS=()
declare -a SKIPPED=()
declare -a TRUNCATED=()

if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
    C_RED=$'\033[31m'; C_YELLOW=$'\033[33m'; C_GREEN=$'\033[32m'
    C_BLUE=$'\033[34m'; C_RESET=$'\033[0m'
else
    C_RED=""; C_YELLOW=""; C_GREEN=""; C_BLUE=""; C_RESET=""
fi
timestamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() { printf '%s %s[%s]%s %s\n' "$(timestamp)" "$2" "$1" "$C_RESET" "${*:3}"; }
info() { log INFO "$C_BLUE" "$@"; }
ok() { log OK "$C_GREEN" "$@"; }
warn() { log WARN "$C_YELLOW" "$@" >&2; }
error() { log ERROR "$C_RED" "$@" >&2; }
die() { error "$*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
note_skip() { SKIPPED+=("$1 -- $2"); warn "skipped $1: $2"; }

usage() {
    cat <<USAGE
$SCRIPT_NAME - package this box's operator activity logs into one Desktop zip

Usage:
  $SCRIPT_NAME [options]

Options:
  --run-dir DIR        Also collect this cptc-linux.sh run directory.
                       Repeatable.  Root-owned run directories need sudo.
  --output DIR         Write the archive here instead of the Desktop.
  --max-file-size MB   Truncate any single collected file larger than this
                       (default $MAX_FILE_MB).  Truncation is recorded in the
                       manifest; nothing is dropped silently.
  --no-sudo-io         Do not collect /var/log/sudo-io.  Those logs contain
                       full terminal output of privileged commands.
  -h, --help           Show this help.

What is collected:
  shell history, script(1) session transcripts and timing files, an export of
  this operator's auditd execve trail, a journald export for the session
  window, process accounting if enabled, sudo I/O logs (unless --no-sudo-io),
  and any run directories you name.

Run it under sudo to capture the root-owned sources.  Without sudo it still
produces a usable archive and records what it could not reach.
USAGE
}

operator_name() { printf '%s' "${SUDO_USER:-$(id -un)}"; }
operator_home() {
    local entry
    entry="$(getent passwd "$(operator_name)" 2>/dev/null)" \
        || die "cannot resolve passwd entry for $(operator_name)"
    printf '%s' "$(printf '%s' "$entry" | cut -d: -f6)"
}

# Resolving "the Desktop" is the single most error-prone part of this script.
# $HOME is wrong under sudo, ~/Desktop may not exist, and on a localized
# desktop the directory is named in the user's own language, which only
# XDG_DESKTOP_DIR records.
resolve_desktop() {
    local home dirs value desktop=""
    home="$(operator_home)"
    dirs="$home/.config/user-dirs.dirs"
    if [[ -r "$dirs" ]]; then
        value="$(grep -E '^[[:space:]]*XDG_DESKTOP_DIR=' "$dirs" 2>/dev/null | tail -1 || true)"
        if [[ -n "$value" ]]; then
            value="${value#*=}"
            value="${value%\"}"
            value="${value#\"}"
            value="${value//\$HOME/$home}"
            desktop="$value"
        fi
    fi
    if [[ -z "$desktop" || ! -d "$desktop" ]]; then
        desktop="$home/Desktop"
    fi
    if [[ ! -d "$desktop" ]]; then
        # Distinguish absent from present-but-unusable.  A Desktop that is a
        # dangling or self-referential symlink fails -d with ELOOP, and
        # reporting that as "not found" sends the operator looking in the
        # wrong place.
        if [[ -L "$desktop" ]]; then
            warn "$desktop is a symlink that does not resolve to a directory (dangling or circular)"
            warn "fix it with: rm '$desktop' && mkdir '$desktop'"
        elif [[ -e "$desktop" ]]; then
            warn "$desktop exists but is not a directory"
        else
            warn "$desktop does not exist"
        fi
        warn "falling back to the operator's home directory"
        desktop="$home"
    fi
    printf '%s' "$desktop"
}

parse_args() {
    while (( $# )); do
        case "$1" in
            --run-dir) [[ -n "${2:-}" ]] || die "--run-dir requires a path"; RUN_DIRS+=("$2"); shift 2 ;;
            --output) [[ -n "${2:-}" ]] || die "--output requires a path"; OUTPUT_DIR="$2"; shift 2 ;;
            --max-file-size)
                [[ "${2:-}" =~ ^[0-9]+$ ]] || die "--max-file-size requires a whole number of megabytes"
                MAX_FILE_MB="$2"; shift 2 ;;
            --no-sudo-io) INCLUDE_SUDO_IO=0; shift ;;
            -h|--help) usage; exit 0 ;;
            *) die "unknown option: $1 (try --help)" ;;
        esac
    done
}

# Copies a file into the staging tree, truncating oversized input honestly.
stage_file() {
    # Split deliberately: `local a=$1 b=$a` declares both names unset before
    # assigning, so the self-reference trips `set -u`.
    local source="$1" relative="$2"
    local destination="$STAGE/$relative" size limit
    [[ -e "$source" ]] || { note_skip "$relative" "source does not exist"; return 0; }
    [[ -r "$source" ]] || { note_skip "$relative" "not readable as $(id -un); re-run under sudo"; return 0; }
    mkdir -p "$(dirname "$destination")" || return 0
    limit=$(( MAX_FILE_MB * 1024 * 1024 ))
    size=$(stat -c %s "$source" 2>/dev/null || echo 0)
    if (( size > limit )); then
        # Keep the tail: the most recent activity is the most relevant.
        tail -c "$limit" "$source" >"$destination" 2>/dev/null || { note_skip "$relative" "copy failed"; return 0; }
        TRUNCATED+=("$relative -- kept the last ${MAX_FILE_MB}MB of ${size} bytes")
        warn "truncated $relative to the last ${MAX_FILE_MB}MB (was $size bytes)"
    else
        cp -p -- "$source" "$destination" 2>/dev/null || { note_skip "$relative" "copy failed"; return 0; }
    fi
    chmod 600 "$destination" 2>/dev/null || true
}

stage_command() {
    local relative="$1"; shift
    local destination="$STAGE/$relative"
    mkdir -p "$(dirname "$destination")" || return 0
    if "$@" >"$destination" 2>/dev/null && [[ -s "$destination" ]]; then
        chmod 600 "$destination" 2>/dev/null || true
    else
        rm -f -- "$destination"
        note_skip "$relative" "command produced no output: $*"
    fi
}

collect_shell() {
    local home dir
    home="$(operator_home)"
    dir="$home/.cptc-logs"
    stage_file "$home/.bash_history" "shell/bash_history"
    if [[ -d "$dir/session" ]]; then
        local file count=0
        while IFS= read -r -d '' file; do
            stage_file "$file" "shell/session/${file##*/}"
            count=$((count + 1))
        done < <(find "$dir/session" -maxdepth 1 -type f \( -name 'session-*.log' -o -name 'session-*.timing' \) -print0 2>/dev/null)
        if (( count )); then
            ok "collected $count session transcript file(s)"
        else
            note_skip "shell/session" "no transcripts present"
        fi
    else
        note_skip "shell/session" "$dir/session does not exist; was 'logging enable' run?"
    fi
}

collect_audit() {
    local enabled="unknown"
    if have auditctl && (( EUID == 0 )); then
        enabled="$(auditctl -s 2>/dev/null | tr ' ' '\n' | grep -A1 '^enabled$' | tail -1 || true)"
        [[ -n "$enabled" ]] || enabled="unknown"
        printf 'audit subsystem enabled flag: %s\n' "$enabled" >"$STAGE/audit/subsystem-state.txt" 2>/dev/null || true
        stage_command "audit/auditctl-status.txt" auditctl -s
        stage_command "audit/auditctl-rules.txt" auditctl -l
        if [[ "$enabled" != 1 ]]; then
            warn "the audit subsystem reports enabled=$enabled, so the execve trail is incomplete or empty"
            SKIPPED+=("audit trail -- subsystem enabled flag was $enabled, not 1")
        fi
    else
        note_skip "audit/auditctl-*" "auditctl needs root"
    fi
    if have ausearch && (( EUID == 0 )); then
        stage_command "audit/execve-${AUDIT_KEY}.log" ausearch -k "$AUDIT_KEY" -i
        stage_command "audit/execve-${AUDIT_KEY}.raw" ausearch -k "$AUDIT_KEY" --raw
    else
        note_skip "audit/execve" "ausearch needs root"
    fi
}

collect_system() {
    if have journalctl; then
        if (( EUID == 0 )); then
            stage_command "system/journal-24h.txt" journalctl --since "24 hours ago" --no-pager
            stage_command "system/journal-cptc-session.txt" journalctl -t cptc-session --no-pager
        else
            stage_command "system/journal-user-24h.txt" journalctl --user --since "24 hours ago" --no-pager
            note_skip "system/journal-24h.txt" "the full system journal needs root"
        fi
    else
        note_skip "system/journal" "journalctl is not available"
    fi
    have lastcomm && stage_command "system/lastcomm.txt" lastcomm
    have last && stage_command "system/last.txt" last -Fw
    stage_command "system/ip-addr.txt" ip -o addr
    stage_command "system/hostname.txt" hostname -f
    stage_command "system/id.txt" id

    if (( INCLUDE_SUDO_IO )); then
        if [[ -d /var/log/sudo-io ]]; then
            if (( EUID == 0 )); then
                mkdir -p "$STAGE/system/sudo-io" || true
                if cp -a /var/log/sudo-io/. "$STAGE/system/sudo-io/" 2>/dev/null; then
                    chmod -R go-rwx "$STAGE/system/sudo-io" 2>/dev/null || true
                    ok "collected sudo I/O session logs"
                    warn "sudo I/O logs contain full terminal output of privileged commands"
                else
                    note_skip "system/sudo-io" "copy failed"
                fi
            else
                note_skip "system/sudo-io" "needs root"
            fi
        else
            note_skip "system/sudo-io" "/var/log/sudo-io does not exist"
        fi
    else
        SKIPPED+=("system/sudo-io -- excluded by --no-sudo-io")
    fi
}

collect_run_dirs() {
    local dir index=0 name
    for dir in "${RUN_DIRS[@]+"${RUN_DIRS[@]}"}"; do
        index=$((index + 1))
        if [[ ! -d "$dir" ]]; then
            note_skip "runs/$index" "$dir is not a directory"
            continue
        fi
        if [[ ! -r "$dir" ]]; then
            note_skip "runs/$index" "$dir is not readable as $(id -un); re-run under sudo"
            continue
        fi
        name="$(basename -- "$dir")"
        mkdir -p "$STAGE/runs/$name" || continue
        if cp -a "$dir/." "$STAGE/runs/$name/" 2>/dev/null; then
            ok "collected run directory $name"
        else
            note_skip "runs/$name" "copy was incomplete"
        fi
    done
}

write_manifest() {
    local manifest="$STAGE/MANIFEST.txt" entry
    {
        printf 'CPTC operator activity log collection\n'
        printf '=====================================\n\n'
        printf 'collected_at_utc   : %s\n' "$(timestamp)"
        printf 'collected_at_local : %s\n' "$(date +'%Y-%m-%dT%H:%M:%S%z (%Z)')"
        printf 'operator           : %s\n' "$(operator_name)"
        printf 'effective_uid      : %s\n' "$EUID"
        printf 'hostname           : %s\n' "$(hostname -f 2>/dev/null || hostname)"
        printf 'kernel             : %s\n' "$(uname -srm)"
        printf 'collector          : %s\n' "$SCRIPT_NAME"
        printf 'max_file_size_mb   : %s\n' "$MAX_FILE_MB"
        printf '\n'
        printf 'tool versions\n-------------\n'
        local tool version
        for tool in bash nmap script auditctl ausearch journalctl zip tar sudo; do
            if have "$tool"; then
                # pipefail makes a pipeline inherit the tool's failure, so the
                # failure is absorbed before head rather than after it.
                version="$({ "$tool" --version 2>&1 || true; } | head -1)"
                [[ -n "$version" ]] || version="(installed; version not reported)"
                printf '  %-10s %s\n' "$tool" "$version"
            else
                printf '  %-10s (absent)\n' "$tool"
            fi
        done
        printf '\n'
        if (( ${#SKIPPED[@]} )); then
            printf 'NOT COLLECTED (%d)\n------------------\n' "${#SKIPPED[@]}"
            for entry in "${SKIPPED[@]}"; do printf '  %s\n' "$entry"; done
        else
            printf 'NOT COLLECTED (0)\n------------------\n  nothing was skipped\n'
        fi
        printf '\n'
        if (( ${#TRUNCATED[@]} )); then
            printf 'TRUNCATED (%d)\n--------------\n' "${#TRUNCATED[@]}"
            for entry in "${TRUNCATED[@]}"; do printf '  %s\n' "$entry"; done
        else
            printf 'TRUNCATED (0)\n--------------\n  no file was truncated\n'
        fi
        printf '\nSHA-256 of every collected file\n-------------------------------\n'
    } >"$manifest"

    # Hash everything except the manifest itself.
    ( cd "$STAGE" && find . -type f ! -name 'MANIFEST.txt' -print0 \
        | sort -z | xargs -0 -r sha256sum ) >>"$manifest" 2>/dev/null || true
    chmod 600 "$manifest" 2>/dev/null || true
}

make_archive() {
    local destination="$1" rc=0
    if have zip; then
        # zip returns 18 when an input file could not be read but the archive
        # it wrote is still valid, so that case is partial success.
        ( cd "$STAGE" && zip -r -q -X "$destination" . ) && rc=0 || rc=$?
        case "$rc" in
            0) ok "archive written with zip" ;;
            18) warn "zip could not read every input (exit 18); the archive is valid but partial" ;;
            *) error "zip failed with exit $rc"; return 1 ;;
        esac
    elif have tar; then
        warn "zip is not installed; writing a .tar.gz instead"
        destination="${destination%.zip}.tar.gz"
        ( cd "$STAGE" && tar -czf "$destination" . ) && rc=0 || rc=$?
        case "$rc" in
            0) ok "archive written with tar" ;;
            1|2) warn "tar reported exit $rc; the archive was written but may be partial" ;;
            *) error "tar failed with exit $rc"; return 1 ;;
        esac
    else
        die "neither zip nor tar is available; cannot package the logs"
    fi
    printf '%s' "$destination" >"$STAGE/.archive-path"
    ARCHIVE_PATH="$destination"
}

main() {
    parse_args "$@"

    have find || die "required command is missing: find"
    have sha256sum || die "required command is missing: sha256sum"

    local desktop stamp host base
    desktop="${OUTPUT_DIR:-$(resolve_desktop)}"
    [[ -d "$desktop" ]] || die "output directory does not exist: $desktop"
    [[ -w "$desktop" ]] || die "output directory is not writable: $desktop"

    stamp="$(date -u +%Y%m%dT%H%M%SZ)"
    host="$(hostname -s 2>/dev/null || echo unknown)"
    base="cptc-logs-${host}-$(operator_name)-${stamp}"

    # Never overwrite a previous collection.
    local candidate="$desktop/$base.zip" suffix=1
    while [[ -e "$candidate" ]]; do
        candidate="$desktop/$base-$suffix.zip"
        suffix=$((suffix + 1))
    done

    STAGE="$(mktemp -d -t cptc-collect-XXXXXX)" || die "could not create a staging directory"
    chmod 700 "$STAGE" || die "could not secure the staging directory"
    # shellcheck disable=SC2064
    trap "rm -rf -- '$STAGE'" EXIT

    info "collecting operator activity logs for $(operator_name) on $host"
    (( EUID == 0 )) || warn "not running as root: auditd, sudo I/O and the system journal will be partial"

    # Flush what we can before packaging.  A shell's in-memory history is only
    # written by that shell, so other open terminals keep their tail until they
    # flush; that limitation is recorded rather than papered over.
    history -a 2>/dev/null || true
    SKIPPED+=("note -- other open shells may hold unflushed history until they exit")

    mkdir -p "$STAGE/shell" "$STAGE/audit" "$STAGE/system" || die "could not build the staging tree"
    collect_shell
    collect_audit
    collect_system
    collect_run_dirs
    write_manifest

    local files bytes
    files="$(find "$STAGE" -type f | wc -l)"
    bytes="$(du -sb "$STAGE" 2>/dev/null | cut -f1 || echo 0)"
    info "staged $files file(s), $bytes bytes"

    make_archive "$candidate" || die "could not create the archive"

    chmod 600 "$ARCHIVE_PATH" || warn "could not set 0600 on the archive"
    if (( EUID == 0 )) && [[ -n "${SUDO_USER:-}" ]]; then
        chown "${SUDO_UID:-$SUDO_USER}:${SUDO_GID:-$(id -g "$SUDO_USER")}" "$ARCHIVE_PATH" 2>/dev/null \
            || warn "could not hand the archive to $SUDO_USER; it is owned by root"
    fi

    ok "activity log archive: $ARCHIVE_PATH"
    info "$(du -h "$ARCHIVE_PATH" 2>/dev/null | cut -f1 || echo '?') on disk, mode 0600"
    (( ${#SKIPPED[@]} )) && info "${#SKIPPED[@]} item(s) not collected; see MANIFEST.txt inside the archive"
    warn "this archive contains your own activity record and may include target output; handle it as engagement-sensitive"
}

main "$@"
