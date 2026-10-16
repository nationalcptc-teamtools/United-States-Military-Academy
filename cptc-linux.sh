#!/usr/bin/env bash
# CPTC Linux enumeration runner
#
# This script is intended for systems and networks that the operator is
# explicitly authorized to assess.  It deliberately separates installation
# from execution, freezes scope before scanning, and records every command.

set -Eeuo pipefail
shopt -s inherit_errexit 2>/dev/null || true
umask 077

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR

DEFAULT_OUTPUT_ROOT="${SCRIPT_DIR}/artifacts"
RUN_DIR=""
MASTER_LOG=""
COMMAND_SEQ=0
EVIDENCE_ARCHIVE_SEQ=0
RUN_STARTED_UTC=""
RESUME_MODE=0
RESUME_LOCK_HELD=0
VERBOSE=1
NMAP_DATA_DIR=""
NMAP_BINARY=""
NMAP_SERVICE_NSE_SCRIPTS=""
NMAP_VULN_NSE_SCRIPTS=""
NMAP_PROCESS_HOME=""
NMAP_PROCESS_XDG_CONFIG=""
NMAP_PROCESS_XDG_DATA=""
NMAP_PROCESS_CWD=""

readonly -a NMAP_REQUIRED_DATA_FILES=(
    nmap-services nmap-service-probes nmap-mac-prefixes nmap-os-db
    nmap-payloads nmap-protocols nmap-rpc nmap.xsl nse_main.lua scripts/script.db
)
readonly -a NMAP_SERVICE_NSE_NAMES=(
    banner http-title http-headers http-methods ssl-cert ssl-enum-ciphers
    ssh-hostkey ssh-auth-methods ssh2-enum-algos smb-protocols smb2-security-mode
    smb2-time smb-enum-shares rdp-enum-encryption rdp-ntlm-info ldap-rootdse
    dns-nsid ftp-anon ftp-syst rpcinfo nfs-showmount smtp-commands
)
readonly -a NMAP_VULN_NSE_NAMES=(ssl-heartbleed smb-vuln-ms17-010)
readonly -a NMAP_ALL_NSE_NAMES=(
    "${NMAP_SERVICE_NSE_NAMES[@]}" "${NMAP_VULN_NSE_NAMES[@]}"
)

# Operational-technology / industrial-control ports.
#
# These are identified but NEVER version-probed or NSE-scanned.  Rationale,
# measured on a loopback listener with the service-phase flags this script
# used before this guard existed (-sV --version-all plus the banner script):
# a device that closes unparsed connections took 15162 connections carrying
# 15159 distinct probe payloads in under seven seconds, because --version-all
# is intensity 9 and walks the whole nmap-service-probes database regardless
# of which service the port is registered to.  Dropping -sV and NSE for these
# ports takes that to a single connection and zero payloads.
#
# That traffic pattern is unacceptable against a safety PLC, a motor drive, a
# Modbus/TCP-to-serial gateway that serialises onto a shared RS-485 bus, or a
# fire/HVAC controller.  A park's ride interlocks sit on exactly these ports
# while the ride is carrying people.  Report them and let a human decide.
readonly -a OT_TCP_PORTS=(
    102    # ISO-TSAP / Siemens S7comm
    502    # Modbus/TCP
    789    # Red Lion Crimson
    1911   # Niagara Fox (Tridium)
    1962   # PCWorx (Phoenix Contact)
    2404   # IEC 60870-5-104
    4840   # OPC-UA
    4843   # OPC-UA over TLS
    4911   # Niagara Fox over TLS
    5006   # Mitsubishi MELSEC / MELSOFT
    5007   # Mitsubishi MELSEC / MELSOFT
    9600   # OMRON FINS
    18245  # GE SRTP
    18246  # GE SRTP
    20000  # DNP3
    20547  # ProConOS / ProConOS eCLR
    44818  # EtherNet/IP explicit messaging (CIP)
)
# 2222/udp is EtherNet/IP implicit cyclic I/O between a safety PLC and its
# remote I/O and drive racks.  It is frequency rank 33 among UDP ports, so
# --top-ports 100 and 250 both selected it before this guard existed.
readonly -a OT_UDP_PORTS=(
    319    # PTP/IEEE-1588 event   - grandmaster clock
    320    # PTP/IEEE-1588 general - best-master-clock election
    789 2222 4840 5006 5007 9600 34962 34963 34964 44818
)
readonly OT_UDP_PORT_RANGES="47808-47823"   # BACnet/IP and alternate networks

# Serial-to-Ethernet device-server data ports (Moxa NPort, Lantronix, Digi).
# These bridge raw TCP onto a shared RS-485 bus, so a connection here can
# occupy a bus that live cyclic polling depends on.  Unlike the ports above
# they are genuinely ambiguous -- an ordinary web service can sit on 3001 or
# 10001 -- so excluding them outright would lose real coverage.  They instead
# get --version-intensity 0, which the loopback measurement showed sends two
# connections and zero application payloads, versus 15162/15159 under
# --version-all.  Identification without a probe database walk.
readonly OT_TCP_LIGHT_RANGES="771,2001-2016,2101-2116,3001-3016,4001-4016,9660-9669,10001-10016"

# Values in this array are masked in the replayable command journal.
declare -a SECRET_VALUES=()

if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
    readonly C_RED=$'\033[31m'
    readonly C_YELLOW=$'\033[33m'
    readonly C_GREEN=$'\033[32m'
    readonly C_BLUE=$'\033[34m'
    readonly C_RESET=$'\033[0m'
else
    readonly C_RED="" C_YELLOW="" C_GREEN="" C_BLUE="" C_RESET=""
fi

timestamp() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

log() {
    local level="$1" color="$2"
    shift 2
    printf '%s %s[%s]%s %s\n' "$(timestamp)" "$color" "$level" "$C_RESET" "$*"
}

info() { log INFO "$C_BLUE" "$@"; }
ok() { log OK "$C_GREEN" "$@"; }
warn() { log WARN "$C_YELLOW" "$@" >&2; }
error() { log ERROR "$C_RED" "$@" >&2; }
die() { error "$*"; exit 1; }

debug() {
    (( VERBOSE >= 2 )) && log DEBUG "$C_BLUE" "$@" || true
}

have() { command -v "$1" >/dev/null 2>&1; }

usage() {
    cat <<'EOF'
CPTC Linux enumeration runner

Usage:
  cptc-linux.sh install [--core|--all] [--yes]
  cptc-linux.sh doctor
  cptc-linux.sh run --scope FILE --authorized [options]
  cptc-linux.sh run --target IP_OR_CIDR --authorized [options]
  cptc-linux.sh resume RUN_DIR --authorized [options]
  cptc-linux.sh report RUN_DIR
  cptc-linux.sh logging enable|verify|revert
  cptc-linux.sh help

Run options:
  --scope FILE                 One authorized IP, CIDR, or FQDN per line
  --target VALUE               Add an authorized IP, CIDR, or FQDN (repeatable)
  --exclude FILE               IPs/CIDRs/FQDNs to remove from scope
  --authorized                 Confirm that the supplied scope is authorized
  --profile quick|standard|deep
                               quick: top TCP ports; standard: quick then full
                               TCP on discovered/open hosts; deep: full TCP on
                               the complete scope (default: standard)
  --udp                        Add bounded UDP enumeration
  --active-web                 Add Nikto and content discovery when installed
  --enable-vuln-scans          Add explicitly bounded vulnerability checks
  --domain DOMAIN              Domain used for DNS/AD record enumeration
  --interface IFACE            Force Nmap to use an interface
  --phases LIST                Comma-separated phase list. Valid phases:
                               discovery,tcp,udp,services,followups,vuln,report
  --output DIR                 Artifact root (default: artifacts/ beside script)
  --label LABEL                Safe label appended to the run directory
  --jobs N                     Nuclei template concurrency (default: 4)
  --max-rate N                 Maximum Nmap packets/second (default: 1000)
  --min-rate N                 Minimum Nmap packets/second; 0 disables it
  --max-retries N              Nmap probe retransmissions (default: 3)
  --host-timeout DURATION      Nmap per-host limit (default: 20m)
  --command-timeout DURATION   Per-command limit (default: 4h)
  --max-addresses N            Scope ceiling (default: 4096)
  --allow-large-scope          Permit scope above --max-addresses
  --max-followups N            Per-protocol follow-up ceiling (default: 512)
  --snmp-community-file FILE   One approved SNMP community per line; mode 0600
  --dry-run                    Log commands without executing scanners
  -v, --verbose                Increase runner verbosity
  -h, --help                   Show help

Scope files allow blank lines and # comments. Nmap target expressions, shell
options, and default routes (0.0.0.0/0 and ::/0) are rejected. Hostnames are
resolved once and their addresses are frozen for the run.

Examples:
  sudo ./cptc-linux.sh run --scope scope.txt --exclude exclude.txt \
    --authorized --profile standard --udp --domain corp.example

  ./cptc-linux.sh resume artifacts/20261014T140000Z-team-a --authorized

  sudo ./cptc-linux.sh logging enable     # turn on the host's own audit trail
  sudo ./cptc-linux.sh logging verify     # prove events are actually recorded
  sudo ./cptc-linux.sh logging revert     # undo what enable installed

Logging actions:
  enable   Timestamped shell history, script(1) session transcripts, auditd
           execve rules keyed to the real login uid, sudo I/O capture, and
           persistent journald. Without root only the shell facilities are
           enabled, and the rest are reported as skipped.
  verify   Writes a marker and reads it back, because configuration state can
           report healthy while nothing is being recorded.
  revert   Removes the drop-in, the audit rules and the shell block, leaving
           pre-existing operator content untouched.

Collect the resulting logs at the end of a session with ./cptc-collect-logs.sh.
EOF
}

install_usage() {
    cat <<'EOF'
Usage: cptc-linux.sh install [--core|--all] [--yes]

Installs packages on Debian/Kali/Ubuntu. --core installs the dependable scan
foundation. --all (the default) also installs optional protocol and reporting
tools that exist in the configured package repositories.
EOF
}

shell_join_sanitized() {
    local arg secret masked
    local -a rendered=()
    for arg in "$@"; do
        masked="$arg"
        for secret in "${SECRET_VALUES[@]:-}"; do
            [[ -n "$secret" && "$masked" == "$secret" ]] && masked='<redacted>'
        done
        printf -v masked '%q' "$masked"
        rendered+=("$masked")
    done
    local IFS=' '
    printf '%s' "${rendered[*]}"
}

safe_slug() {
    local value="$1"
    value="${value//[^A-Za-z0-9._-]/_}"
    value="${value:0:100}"
    [[ -n "$value" ]] || value="command"
    printf '%s' "$value"
}

append_event() {
    [[ -n "$RUN_DIR" ]] || return 0
    local phase="$1" name="$2" status="$3" rc="$4" duration="$5" raw_log="$6"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(timestamp)" "$phase" "$name" "$status" "$rc" "$duration" "$raw_log" \
        >>"$RUN_DIR/logs/events.tsv"
}

run_logged() {
    # run_logged PHASE NAME TIMEOUT -- command [args...]
    local phase="$1" name="$2" limit="$3"
    shift 3
    [[ "${1:-}" == "--" ]] || die "internal error: run_logged requires --"
    shift
    (( $# > 0 )) || die "internal error: empty command"

    COMMAND_SEQ=$((COMMAND_SEQ + 1))
    local seq slug raw_log command_text start_epoch end_epoch elapsed rc tee_rc
    local -a pipeline_status=()
    printf -v seq '%04d' "$COMMAND_SEQ"
    slug="$(safe_slug "$name")"
    raw_log="$RUN_DIR/raw/${seq}_${slug}.log"
    command_text="$(shell_join_sanitized "$@")"

    printf '# %s phase=%s name=%s\n%s\n\n' "$(timestamp)" "$phase" "$name" "$command_text" \
        >>"$RUN_DIR/logs/commands.sanitized.sh"
    info "[$phase] $name"
    debug "command: $command_text"
    append_event "$phase" "$name" START 0 0 "${raw_log#"$RUN_DIR"/}"

    if (( DRY_RUN )); then
        set +e
        printf 'DRY RUN: %s\n' "$command_text" | tee -a "$raw_log"
        pipeline_status=("${PIPESTATUS[@]}")
        set -e
        tee_rc="${pipeline_status[1]}"
        if (( tee_rc != 0 )); then
            error "[$phase] raw dry-run logging failed for $name (tee exit $tee_rc)"
            append_event "$phase" "$name" FAILED "$tee_rc" 0 "${raw_log#"$RUN_DIR"/}"
            return "$tee_rc"
        fi
        append_event "$phase" "$name" DRY_RUN 0 0 "${raw_log#"$RUN_DIR"/}"
        return 0
    fi

    start_epoch="$(date +%s)"
    local -a runner=("$@")
    if [[ -n "$limit" && "$limit" != "0" ]]; then
        # --foreground keeps the scanner in this runner's process group.  Without
        # it GNU timeout calls setpgid(), so a terminal Ctrl-C (which signals only
        # the foreground group) never reaches nmap and the scan keeps running.
        runner=(timeout --foreground --signal=INT --kill-after=15s "$limit" "${runner[@]}")
    fi

    set +e
    "${runner[@]}" 2>&1 | tee -a "$raw_log"
    pipeline_status=("${PIPESTATUS[@]}")
    set -e
    rc="${pipeline_status[0]}"
    tee_rc="${pipeline_status[1]}"
    if (( tee_rc != 0 )); then
        error "[$phase] raw output logging failed for $name (tee exit $tee_rc)"
        (( rc == 0 )) && rc="$tee_rc"
    fi
    end_epoch="$(date +%s)"
    elapsed=$((end_epoch - start_epoch))

    if (( rc == 0 )); then
        append_event "$phase" "$name" OK "$rc" "$elapsed" "${raw_log#"$RUN_DIR"/}"
        ok "[$phase] $name completed in ${elapsed}s"
    else
        append_event "$phase" "$name" FAILED "$rc" "$elapsed" "${raw_log#"$RUN_DIR"/}"
        printf '%s\t%s\t%s\t%s\t%s\n' "$(timestamp)" "$phase" "$name" "$rc" "${raw_log#"$RUN_DIR"/}" \
            >>"$RUN_DIR/logs/errors.tsv"
        warn "[$phase] $name exited $rc after ${elapsed}s"
    fi
    return "$rc"
}

run_optional() {
    if ! run_logged "$@"; then
        warn "Optional check failed; continuing with the remaining enumeration"
        return 0
    fi
}

archive_evidence_files() {
    # Preserve superseded or partial tool output without leaving it in the
    # current-evidence paths consumed by reports and later phases.
    local label="$1"
    shift
    local path history_dir=""
    local -a existing=()
    for path in "$@"; do
        [[ -e "$path" || -L "$path" ]] && existing+=("$path")
    done
    ((${#existing[@]})) || return 0

    EVIDENCE_ARCHIVE_SEQ=$((EVIDENCE_ARCHIVE_SEQ + 1))
    local history_root="$RUN_DIR/raw/history" resolved_run="" resolved_history=""
    if [[ ! -d "$RUN_DIR/raw" || -L "$RUN_DIR/raw" || -L "$history_root" ]]; then
        error "Evidence history path must use real directories inside this run"
        return 1
    fi
    if ! mkdir -p -- "$history_root"; then
        error "Could not create evidence history root: ${history_root#"$RUN_DIR"/}"
        return 1
    fi
    resolved_run="$(readlink -f -- "$RUN_DIR")" || return 1
    resolved_history="$(readlink -f -- "$history_root")" || return 1
    if [[ "$resolved_history" != "$resolved_run/raw/history" ]]; then
        error "Evidence history path resolves outside its fixed run location"
        return 1
    fi
    history_dir="$history_root/$(date -u '+%Y%m%dT%H%M%SZ')-$(safe_slug "$label")-$$-$EVIDENCE_ARCHIVE_SEQ"
    if ! mkdir -- "$history_dir"; then
        error "Could not create evidence history directory: ${history_dir#"$RUN_DIR"/}"
        return 1
    fi
    for path in "${existing[@]}"; do
        if ! mv -- "$path" "$history_dir/${path##*/}"; then
            error "Could not archive evidence file: ${path#"$RUN_DIR"/}"
            return 1
        fi
    done
    info "Archived ${#existing[@]} prior/partial evidence file(s) under ${history_dir#"$RUN_DIR"/}"
}

validate_json_lines() {
    local path="$1"
    python3 -I - "$path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    with path.open(encoding="utf-8", errors="strict") as handle:
        for number, line in enumerate(handle, 1):
            if not line.strip():
                continue
            value = json.loads(line)
            if not isinstance(value, dict):
                raise ValueError(f"line {number} is not a JSON object")
except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as exc:
    print(f"invalid JSONL output {path}: {exc}", file=sys.stderr)
    raise SystemExit(1)
PY
}

validate_json_document() {
    local path="$1"
    python3 -I - "$path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    value = json.loads(path.read_text(encoding="utf-8", errors="strict"))
    if not isinstance(value, (dict, list)):
        raise ValueError("top-level value is not an object or array")
except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as exc:
    print(f"invalid JSON output {path}: {exc}", file=sys.stderr)
    raise SystemExit(1)
PY
}

validate_nmap_xml() {
    local path="$1"
    [[ -f "$path" && ! -L "$path" && -s "$path" ]] || {
        error "Nmap did not create a fresh nonempty XML file: ${path#"$RUN_DIR"/}"
        return 1
    }
    python3 -I - "$path" <<'PY'
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

path = Path(sys.argv[1])
try:
    root = ET.parse(path).getroot()
except (ET.ParseError, OSError) as exc:
    print(f"invalid Nmap XML {path}: {exc}", file=sys.stderr)
    raise SystemExit(1)

root_name = root.tag.rsplit("}", 1)[-1]
if root_name != "nmaprun":
    print(f"invalid Nmap XML {path}: root element is {root_name!r}", file=sys.stderr)
    raise SystemExit(1)
finished = root.find("./runstats/finished")
if finished is None or finished.get("exit") != "success":
    print(f"incomplete Nmap XML {path}: missing successful runstats/finished marker", file=sys.stderr)
    raise SystemExit(1)
PY
}

record_invalid_optional_output() {
    local phase="$1" name="$2" output="$3"
    printf '%s\t%s\t%s\t%s\t%s\n' "$(timestamp)" "$phase" "$name" 65 "${output#"$RUN_DIR"/}" \
        >>"$RUN_DIR/logs/errors.tsv"
    append_event "$phase" "$name" INVALID_OUTPUT 65 0 "${output#"$RUN_DIR"/}"
    warn "[$phase] $name did not produce valid structured output; it was not promoted as current evidence"
}

record_invalid_nmap_output() {
    local phase="$1" name="$2" output="$3"
    printf '%s\t%s\t%s\t%s\t%s\n' "$(timestamp)" "$phase" "$name" 65 "${output#"$RUN_DIR"/}" \
        >>"$RUN_DIR/logs/errors.tsv"
    append_event "$phase" "$name" INVALID_OUTPUT 65 0 "${output#"$RUN_DIR"/}"
    error "[$phase] $name did not produce complete successful Nmap XML"
}

finish_optional_output() {
    # finish_optional_output PHASE NAME FORMAT TEMP FINAL COMMAND_RC
    local phase="$1" name="$2" format="$3" temporary="$4" final="$5" command_rc="$6"
    if (( command_rc != 0 )); then
        archive_evidence_files "${phase}-${name}-partial" "$temporary" || return 1
        warn "Optional check failed; continuing with the remaining enumeration"
        return 0
    fi

    if [[ ! -f "$temporary" ]]; then
        record_invalid_optional_output "$phase" "$name" "$temporary"
        return 0
    fi
    local valid=0
    case "$format" in
        jsonl) validate_json_lines "$temporary" && valid=1 ;;
        json) validate_json_document "$temporary" && valid=1 ;;
        *) die "internal error: unsupported structured output format: $format" ;;
    esac
    if (( valid == 0 )); then
        record_invalid_optional_output "$phase" "$name" "$temporary"
        archive_evidence_files "${phase}-${name}-invalid" "$temporary" || return 1
        return 0
    fi
    if ! mv -f -- "$temporary" "$final"; then
        error "[$phase] Could not promote validated output: ${final#"$RUN_DIR"/}"
        return 1
    fi
    ok "[$phase] Promoted validated output: ${final#"$RUN_DIR"/}"
}

record_skip() {
    local phase="$1" name="$2" reason="$3"
    info "[$phase] skipping $name: $reason"
    append_event "$phase" "$name" SKIPPED 0 0 "$reason"
}

validate_run_directory_layout() {
    # validate_run_directory_layout REQUIRE_ALL
    local require_all="$1" directory path
    [[ -d "$RUN_DIR" && ! -L "$RUN_DIR" ]] \
        || die "run directory must be a real directory, not a symbolic link: $RUN_DIR"
    for directory in raw logs scope targets reports .state; do
        path="$RUN_DIR/$directory"
        if [[ -e "$path" || -L "$path" ]]; then
            [[ -d "$path" && ! -L "$path" ]] \
                || die "run path must be a real directory, not a symbolic link: $path"
        elif (( require_all )); then
            die "run directory is incomplete: missing $directory/"
        fi
    done
    local state_entry
    if [[ -d "$RUN_DIR/.state" ]]; then
        while IFS= read -r -d '' state_entry; do
            [[ ! -L "$state_entry" && ( -d "$state_entry" || -f "$state_entry" ) ]] \
                || die "state directory contains an unsupported path: $state_entry"
        done < <(find "$RUN_DIR/.state" -mindepth 1 -print0)
    fi
    [[ ! -e "$RUN_DIR/.state/run.lock" || \
        ( -f "$RUN_DIR/.state/run.lock" && ! -L "$RUN_DIR/.state/run.lock" ) ]] \
        || die "run lock must be a regular file, not a symbolic or special path"
}

validate_log_directory_contents() {
    local entry
    while IFS= read -r -d '' entry; do
        [[ -f "$entry" && ! -L "$entry" ]] \
            || die "log directory contains an unsupported path: $entry"
    done < <(find "$RUN_DIR/logs" -mindepth 1 -maxdepth 1 -print0)
}

validate_covered_artifact_layout() {
    python3 -I - "$RUN_DIR" <<'PY'
import sys
from pathlib import Path

run_dir = Path(sys.argv[1]).resolve()
for name in ("scope", "raw", "targets", "reports"):
    root = run_dir / name
    if root.is_symlink() or not root.is_dir():
        print(f"covered artifact root must be a real directory: {root}", file=sys.stderr)
        raise SystemExit(1)
    for path in root.rglob("*"):
        if path.is_symlink():
            print(f"symbolic links are not allowed in covered artifacts: {path.relative_to(run_dir)}", file=sys.stderr)
            raise SystemExit(1)
        if not path.is_dir() and not path.is_file():
            print(f"unsupported path in covered artifacts: {path.relative_to(run_dir)}", file=sys.stderr)
            raise SystemExit(1)
PY
}

init_logging() {
    validate_run_directory_layout 0
    mkdir -p -- "$RUN_DIR"/{raw,logs,scope,targets,reports,.state}
    validate_run_directory_layout 1
    chmod 700 "$RUN_DIR" "$RUN_DIR"/{raw,logs,scope,targets,reports,.state}
    validate_log_directory_contents
    local prior_log prior_sequence
    for prior_log in "$RUN_DIR"/raw/[0-9]*_*.log; do
        [[ -e "$prior_log" ]] || continue
        prior_sequence="${prior_log##*/}"
        prior_sequence="${prior_sequence%%_*}"
        [[ "$prior_sequence" =~ ^[0-9]+$ ]] || continue
        (( 10#$prior_sequence > COMMAND_SEQ )) && COMMAND_SEQ=$((10#$prior_sequence))
    done
    MASTER_LOG="$RUN_DIR/logs/run.log"
    local log_file
    for log_file in "$MASTER_LOG" "$RUN_DIR/logs/events.tsv" "$RUN_DIR/logs/errors.tsv" \
        "$RUN_DIR/logs/commands.sanitized.sh"; do
        [[ ! -L "$log_file" ]] || die "log file must not be a symbolic link: $log_file"
        [[ ! -e "$log_file" || -f "$log_file" ]] \
            || die "log path must be a regular file: $log_file"
    done
    touch "$MASTER_LOG" "$RUN_DIR/logs/events.tsv" "$RUN_DIR/logs/errors.tsv" \
        "$RUN_DIR/logs/commands.sanitized.sh"
    validate_log_directory_contents
    find "$RUN_DIR/logs" -mindepth 1 -maxdepth 1 -type f -exec chmod 600 -- {} +
    exec > >(tee -a "$MASTER_LOG") 2> >(tee -a "$MASTER_LOG" >&2)
    info "$SCRIPT_NAME $SCRIPT_VERSION"
    info "Run directory: $RUN_DIR"
}

absolute_path() {
    python3 -I - "$1" <<'PY'
import os, sys
print(os.path.abspath(os.path.expanduser(sys.argv[1])))
PY
}

check_positive_integer() {
    local name="$1" value="$2" allow_zero="${3:-0}"
    [[ "$value" =~ ^[0-9]+$ ]] || die "$name must be an integer"
    if (( allow_zero )); then
        (( value >= 0 )) || die "$name must be zero or greater"
    else
        (( value > 0 )) || die "$name must be greater than zero"
    fi
}

check_duration() {
    local name="$1" value="$2"
    [[ "$value" =~ ^[1-9][0-9]*([smhd])?$ ]] || die "$name must look like 30s, 20m, 4h, or 1d"
}

validate_domain() {
    local domain="$1"
    [[ ${#domain} -le 253 && "$domain" != -* ]] || return 1
    [[ "$domain" =~ ^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)*[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.?$ ]]
}

install_packages() {
    local mode="all" assume_yes=0
    while (( $# )); do
        case "$1" in
            --core) mode="core" ;;
            --all) mode="all" ;;
            --yes|-y) assume_yes=1 ;;
            -h|--help) install_usage; return 0 ;;
            *) die "unknown install option: $1" ;;
        esac
        shift
    done

    have apt-get || die "automatic installation currently supports Debian/Kali/Ubuntu (apt-get)"
    local -a root=()
    if (( EUID != 0 )); then
        have sudo || die "install requires root or sudo"
        root=(sudo)
        "${root[@]}" -v
    fi

    local -a apt_yes=()
    (( assume_yes )) && apt_yes=(-y)
    local -a core_packages=(
        nmap python3 jq curl ca-certificates iproute2 util-linux dnsutils smbclient
        ldap-utils snmp rpcbind nfs-common openssl netcat-openbsd xsltproc
    )
    local -a optional_packages=(
        arp-scan onesixtyone whatweb nikto sslscan testssl.sh ssh-audit swaks
        ipmitool enum4linux-ng netexec gobuster ffuf seclists
        exploitdb eyewitness nuclei httpx-toolkit
    )

    info "Refreshing apt package metadata"
    "${root[@]}" apt-get update
    info "Installing core enumeration packages"
    "${root[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install "${apt_yes[@]}" \
        --no-install-recommends "${core_packages[@]}"

    if [[ "$mode" == "all" ]]; then
        local package
        for package in "${optional_packages[@]}"; do
            if apt-cache show "$package" >/dev/null 2>&1; then
                info "Installing optional package: $package"
                if ! "${root[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install "${apt_yes[@]}" \
                    --no-install-recommends "$package"; then
                    warn "Could not install optional package $package"
                fi
            else
                warn "Optional package is unavailable in configured repositories: $package"
            fi
        done

        hash -r
        if have nuclei; then
            info "Downloading Nuclei templates now so competition scans do not need internet access"
            if (( EUID == 0 )) && [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]] && have runuser; then
                local invoking_home
                invoking_home="$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6 || true)"
                if [[ -z "$invoking_home" ]]; then
                    warn "Could not determine the home directory for $SUDO_USER; Nuclei templates were not downloaded"
                elif ! runuser -u "$SUDO_USER" -- env HOME="$invoking_home" nuclei -update-templates -verbose; then
                    warn "Nuclei template download failed for $SUDO_USER; retry before the competition"
                fi
            elif ! nuclei -update-templates -verbose; then
                warn "Nuclei template download failed; retry before the competition"
            fi
        fi
    fi

    ok "Package installation finished"
    doctor || true
}

doctor() {
    local missing=0 command_name resolved
    local -a required=(bash python3 nmap timeout tee awk sed sort sha256sum flock env find readlink cmp mktemp)
    local -a optional=(
        jq curl dig smbclient rpcclient ldapsearch snmpwalk rpcinfo showmount
        ssh-keyscan whatweb nikto gobuster ffuf sslscan testssl
        ssh-audit onesixtyone nxc netexec enum4linux-ng nuclei httpx-toolkit
        searchsploit swaks ipmitool xsltproc arp-scan
    )

    printf 'CPTC Linux runner %s\n' "$SCRIPT_VERSION"
    printf 'System: '
    if [[ -r /etc/os-release ]]; then
        (
            # This standard system file is checked above.
            # shellcheck disable=SC1091
            . /etc/os-release
            printf '%s\n' "${PRETTY_NAME:-unknown}"
        )
    else
        uname -a
    fi
    printf 'Kernel: %s\n' "$(uname -srmo 2>/dev/null || uname -a)"
    if (( EUID == 0 )); then
        printf 'Privilege: root\n\n'
    else
        printf 'Privilege: unprivileged\n\n'
    fi

    printf 'Required commands:\n'
    for command_name in "${required[@]}"; do
        if resolved="$(command -v "$command_name" 2>/dev/null)"; then
            printf '  [ok]      %-18s %s\n' "$command_name" "$resolved"
        else
            printf '  [missing] %s\n' "$command_name"
            missing=$((missing + 1))
        fi
    done

    printf '\nOptional commands:\n'
    for command_name in "${optional[@]}"; do
        if resolved="$(command -v "$command_name" 2>/dev/null)"; then
            printf '  [ok]      %-18s %s\n' "$command_name" "$resolved"
        else
            printf '  [skip]    %s\n' "$command_name"
        fi
    done

    if have httpx; then
        if httpx -version 2>&1 | grep -qi projectdiscovery; then
            printf '  [ok]      %-18s %s\n' 'httpx (PD)' "$(command -v httpx)"
        else
            printf '  [note]    httpx exists but does not appear to be ProjectDiscovery httpx\n'
        fi
    fi

    if have nuclei; then
        local nuclei_templates=""
        nuclei_templates="$(find_nuclei_templates || true)"
        if [[ -n "$nuclei_templates" ]]; then
            printf '  [ok]      %-18s %s\n' 'nuclei templates' "$nuclei_templates"
            nuclei -templates-version -disable-update-check 2>&1 | sed -n '1,3p' || true
        else
            printf '  [missing] nuclei templates (run: nuclei -update-templates)\n'
        fi
    fi

    if (( missing )); then
        printf '\nMissing %d required command(s). Run: sudo ./%s install --all\n' "$missing" "$SCRIPT_NAME"
        return 1
    fi
    printf '\nRequired scan foundation is ready.\n'
}

set_run_defaults() {
    PROFILE="standard"
    OUTPUT_ROOT="$DEFAULT_OUTPUT_ROOT"
    LABEL="cptc"
    SCOPE_FILE=""
    EXCLUDE_FILE=""
    DOMAIN=""
    INTERFACE=""
    PHASES=""
    AUTHORIZED=0
    UDP_ENABLED=0
    ACTIVE_WEB=0
    VULN_ENABLED=0
    ALLOW_LARGE_SCOPE=0
    MAX_ADDRESSES=4096
    JOBS=4
    MAX_RATE=1000
    MIN_RATE=0
    MAX_RETRIES=3
    HOST_TIMEOUT="20m"
    COMMAND_TIMEOUT="4h"
    MAX_FOLLOWUPS=512
    DRY_RUN=0
    SNMP_COMMUNITY_FILE=""
    CUSTOM_SNMP_REQUIRED=0
    declare -ga TARGET_ARGS=()
}

load_resume_settings() {
    local state_dir="$RUN_DIR/.state"
    [[ -d "$state_dir" ]] || die "not a CPTC run directory: $RUN_DIR"
    verify_resume_settings
    [[ -r "$state_dir/profile" ]] && PROFILE="$(<"$state_dir/profile")"
    [[ -r "$state_dir/domain" ]] && DOMAIN="$(<"$state_dir/domain")"
    [[ -r "$state_dir/interface" ]] && INTERFACE="$(<"$state_dir/interface")"
    [[ -r "$state_dir/phases" ]] && PHASES="$(<"$state_dir/phases")"
    [[ -r "$state_dir/udp_enabled" ]] && UDP_ENABLED="$(<"$state_dir/udp_enabled")"
    [[ -r "$state_dir/active_web" ]] && ACTIVE_WEB="$(<"$state_dir/active_web")"
    [[ -r "$state_dir/vuln_enabled" ]] && VULN_ENABLED="$(<"$state_dir/vuln_enabled")"
    [[ -r "$state_dir/max_rate" ]] && MAX_RATE="$(<"$state_dir/max_rate")"
    [[ -r "$state_dir/min_rate" ]] && MIN_RATE="$(<"$state_dir/min_rate")"
    [[ -r "$state_dir/max_retries" ]] && MAX_RETRIES="$(<"$state_dir/max_retries")"
    [[ -r "$state_dir/host_timeout" ]] && HOST_TIMEOUT="$(<"$state_dir/host_timeout")"
    [[ -r "$state_dir/command_timeout" ]] && COMMAND_TIMEOUT="$(<"$state_dir/command_timeout")"
    [[ -r "$state_dir/max_followups" ]] && MAX_FOLLOWUPS="$(<"$state_dir/max_followups")"
    [[ -r "$state_dir/jobs" ]] && JOBS="$(<"$state_dir/jobs")"
    [[ -r "$state_dir/custom_snmp_required" ]] && CUSTOM_SNMP_REQUIRED="$(<"$state_dir/custom_snmp_required")"
    SCOPE_FILE="$RUN_DIR/scope/requested.txt"
    [[ -s "$RUN_DIR/scope/excluded.requested.txt" ]] && EXCLUDE_FILE="$RUN_DIR/scope/excluded.requested.txt"
    return 0
}

parse_run_args() {
    while (( $# )); do
        case "$1" in
            --scope)
                (( $# >= 2 )) || die "--scope requires a file"
                (( RESUME_MODE == 0 )) || die "scope cannot be changed during resume"
                SCOPE_FILE="$2"; shift ;;
            --target)
                (( $# >= 2 )) || die "--target requires a value"
                (( RESUME_MODE == 0 )) || die "scope cannot be changed during resume"
                TARGET_ARGS+=("$2"); shift ;;
            --exclude)
                (( $# >= 2 )) || die "--exclude requires a file"
                (( RESUME_MODE == 0 )) || die "exclusions cannot be changed during resume"
                EXCLUDE_FILE="$2"; shift ;;
            --authorized) AUTHORIZED=1 ;;
            --profile)
                (( RESUME_MODE == 0 )) || die "profile cannot be changed during resume"
                (( $# >= 2 )) || die "--profile requires a value"; PROFILE="$2"; shift ;;
            --udp) (( RESUME_MODE == 0 )) || die "UDP selection cannot be changed during resume"; UDP_ENABLED=1 ;;
            --active-web) (( RESUME_MODE == 0 )) || die "active-web selection cannot be changed during resume"; ACTIVE_WEB=1 ;;
            --enable-vuln-scans) (( RESUME_MODE == 0 )) || die "vulnerability scan selection cannot be changed during resume"; VULN_ENABLED=1 ;;
            --domain)
                (( RESUME_MODE == 0 )) || die "domain cannot be changed during resume"
                (( $# >= 2 )) || die "--domain requires a value"; DOMAIN="$2"; shift ;;
            --interface)
                (( RESUME_MODE == 0 )) || die "interface cannot be changed during resume"
                (( $# >= 2 )) || die "--interface requires a value"; INTERFACE="$2"; shift ;;
            --phases)
                (( RESUME_MODE == 0 )) || die "phase selection cannot be changed during resume"
                (( $# >= 2 )) || die "--phases requires a list"; PHASES="$2"; shift ;;
            --output)
                (( $# >= 2 )) || die "--output requires a directory"
                (( RESUME_MODE == 0 )) || die "--output is not valid during resume"
                OUTPUT_ROOT="$2"; shift ;;
            --label)
                (( RESUME_MODE == 0 )) || die "label is not valid during resume"
                (( $# >= 2 )) || die "--label requires a value"; LABEL="$2"; shift ;;
            --jobs) (( $# >= 2 )) || die "--jobs requires a value"; JOBS="$2"; shift ;;
            --max-rate) (( $# >= 2 )) || die "--max-rate requires a value"; MAX_RATE="$2"; shift ;;
            --min-rate) (( $# >= 2 )) || die "--min-rate requires a value"; MIN_RATE="$2"; shift ;;
            --max-retries) (( $# >= 2 )) || die "--max-retries requires a value"; MAX_RETRIES="$2"; shift ;;
            --host-timeout) (( $# >= 2 )) || die "--host-timeout requires a value"; HOST_TIMEOUT="$2"; shift ;;
            --command-timeout) (( $# >= 2 )) || die "--command-timeout requires a value"; COMMAND_TIMEOUT="$2"; shift ;;
            --max-addresses)
                (( RESUME_MODE == 0 )) || die "scope ceiling cannot be changed during resume"
                (( $# >= 2 )) || die "--max-addresses requires a value"; MAX_ADDRESSES="$2"; shift ;;
            --allow-large-scope) (( RESUME_MODE == 0 )) || die "scope size policy cannot be changed during resume"; ALLOW_LARGE_SCOPE=1 ;;
            --max-followups) (( $# >= 2 )) || die "--max-followups requires a value"; MAX_FOLLOWUPS="$2"; shift ;;
            --snmp-community-file) (( $# >= 2 )) || die "--snmp-community-file requires a file"; SNMP_COMMUNITY_FILE="$2"; shift ;;
            --dry-run) (( RESUME_MODE == 0 )) || die "--dry-run is not valid during resume"; DRY_RUN=1 ;;
            -v|--verbose) VERBOSE=$((VERBOSE + 1)) ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            *) die "unknown run option: $1" ;;
        esac
        shift
    done
    (( $# == 0 )) || die "unexpected arguments: $*"
}

validate_run_options() {
    [[ "$PROFILE" == quick || "$PROFILE" == standard || "$PROFILE" == deep ]] \
        || die "profile must be quick, standard, or deep"
    (( AUTHORIZED == 1 )) || die "run requires --authorized after you verify the supplied competition scope"
    check_positive_integer --jobs "$JOBS"
    check_positive_integer --max-rate "$MAX_RATE"
    check_positive_integer --min-rate "$MIN_RATE" 1
    check_positive_integer --max-retries "$MAX_RETRIES" 1
    check_positive_integer --max-addresses "$MAX_ADDRESSES"
    check_positive_integer --max-followups "$MAX_FOLLOWUPS"
    check_duration --host-timeout "$HOST_TIMEOUT"
    check_duration --command-timeout "$COMMAND_TIMEOUT"
    [[ "$LABEL" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || die "label contains unsupported characters"
    [[ -z "$DOMAIN" ]] || validate_domain "$DOMAIN" || die "invalid domain: $DOMAIN"
    [[ -z "$INTERFACE" || "$INTERFACE" =~ ^[A-Za-z0-9_.:-]+$ ]] || die "invalid interface name"
    if [[ -n "$INTERFACE" ]] && have ip && ! ip link show dev "$INTERFACE" >/dev/null 2>&1; then
        die "interface does not exist: $INTERFACE"
    fi
    [[ -z "$SNMP_COMMUNITY_FILE" || -r "$SNMP_COMMUNITY_FILE" ]] || die "cannot read SNMP community file"
    if [[ -n "$SNMP_COMMUNITY_FILE" ]]; then
        local mode
        mode="$(stat -c '%a' "$SNMP_COMMUNITY_FILE" 2>/dev/null || true)"
        [[ "$mode" == 600 || "$mode" == 400 ]] || die "SNMP community file must have mode 0600 or 0400"
    fi
    if (( RESUME_MODE && CUSTOM_SNMP_REQUIRED )) && phase_requested followups \
        && [[ -z "$SNMP_COMMUNITY_FILE" ]]; then
        die "this run used custom SNMP communities; repeat --snmp-community-file FILE when resuming"
    fi

    if [[ -z "$PHASES" ]]; then
        PHASES="discovery,tcp,services,followups,report"
        (( UDP_ENABLED )) && PHASES="discovery,tcp,udp,services,followups,report"
        (( VULN_ENABLED )) && PHASES="${PHASES%,report},vuln,report"
    fi
    local phase
    local -a requested_phases=()
    IFS=',' read -r -a requested_phases <<<"$PHASES"
    for phase in "${requested_phases[@]}"; do
        case "$phase" in
            discovery|tcp|udp|services|followups|vuln|report) ;;
            *) die "unknown phase: $phase" ;;
        esac
    done
    [[ ",$PHASES," != *,udp,* || $UDP_ENABLED -eq 1 ]] || UDP_ENABLED=1
    [[ ",$PHASES," != *,vuln,* || $VULN_ENABLED -eq 1 ]] \
        || die "the vuln phase also requires --enable-vuln-scans"
    # Nmap cannot send raw UDP probes unprivileged.  Refuse now rather than
    # failing the udp phase later, which would tear down every phase after it.
    if (( DRY_RUN == 0 && EUID != 0 )) && phase_requested udp; then
        die "UDP enumeration requires root: re-run under sudo, or drop --udp (and 'udp' from --phases)"
    fi
}

record_tool_provenance() {
    local command_name="$1" resolved canonical digest package="" package_version="" tool_version=""
    resolved="$(command -v "$command_name")"
    canonical="$(readlink -f -- "$resolved" 2>/dev/null || printf '%s' "$resolved")"
    digest="$(sha256sum "$canonical" 2>/dev/null | awk '{print $1}')"
    if have dpkg-query; then
        package="$(dpkg-query -S "$canonical" 2>/dev/null | head -n 1 | cut -d: -f1 || true)"
        if [[ -n "$package" ]]; then
            package_version="$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true)"
        fi
    fi
    case "$command_name" in
        python3|curl|smbclient|rpcclient|snmpwalk|whatweb|sslscan|ssh-audit|nxc|netexec|enum4linux-ng)
            tool_version="$("$command_name" --version 2>&1 | head -n 1 || true)" ;;
        nmap) tool_version="version probe omitted; executable and data-tree hashes are frozen separately" ;;
        dig) tool_version="$(dig -v 2>&1 | head -n 1 || true)" ;;
        ldapsearch) tool_version="$(ldapsearch -VV 2>&1 | head -n 1 || true)" ;;
        ssh-keyscan) tool_version="$(ssh -V 2>&1 | head -n 1 || true)" ;;
        nikto) tool_version="$(nikto -Version 2>&1 | head -n 1 || true)" ;;
        gobuster) tool_version="$(gobuster version 2>&1 | head -n 1 || true)" ;;
        ffuf) tool_version="$(ffuf -V 2>&1 | head -n 1 || true)" ;;
        nuclei|httpx|httpx-toolkit) tool_version="$("$command_name" -version 2>&1 | head -n 1 || true)" ;;
        swaks|xsltproc) tool_version="$("$command_name" --version 2>&1 | head -n 1 || true)" ;;
        *) tool_version="version probe not defined; use package version and binary hash" ;;
    esac
    tool_version="${tool_version//$'\t'/ }"
    printf '%s\t%s\tsha256=%s\tpackage=%s\tpackage_version=%s\t%s\n' \
        "$command_name" "$canonical" "${digest:-unavailable}" "${package:-unmanaged}" \
        "${package_version:-unavailable}" "$tool_version"
}

hash_nuclei_template_tree() {
    local template_root="$1"
    python3 -I - "$template_root" <<'PY'
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
if not root.is_dir():
    print(f"Nuclei template root is not a directory: {root}", file=sys.stderr)
    raise SystemExit(1)

digest = hashlib.sha256()
count = 0
for path in sorted(root.rglob("*")):
    relative = path.relative_to(root)
    if ".git" in relative.parts:
        continue
    if path.is_symlink():
        print(f"Nuclei template tree contains a symbolic link: {relative}", file=sys.stderr)
        raise SystemExit(1)
    if path.is_dir():
        continue
    if not path.is_file():
        print(f"Nuclei template tree contains an unsupported file type: {relative}", file=sys.stderr)
        raise SystemExit(1)
    relative_bytes = relative.as_posix().encode("utf-8")
    digest.update(len(relative_bytes).to_bytes(4, "big"))
    digest.update(relative_bytes)
    content = path.read_bytes()
    digest.update(len(content).to_bytes(8, "big"))
    digest.update(content)
    count += 1
print(f"{count}\t{digest.hexdigest()}")
PY
}

write_nuclei_template_provenance() {
    local template_root="$1" metadata="$2" destination="$RUN_DIR/scope/nuclei-template-tree.json"
    local template_count="" template_digest="" temporary="$RUN_DIR/.state/nuclei-template-tree.tmp.$$.$RANDOM"
    IFS=$'\t' read -r template_count template_digest <<<"$metadata"
    [[ "$template_count" =~ ^[0-9]+$ && "$template_digest" =~ ^[0-9a-f]{64}$ ]] \
        || { error "Invalid Nuclei template provenance metadata"; return 1; }
    if ! python3 -I - "$template_root" "$template_count" "$template_digest" "$temporary" <<'PY'
import json
import os
import sys
from pathlib import Path

root, count, digest, output = sys.argv[1:]
document = {
    "directory": str(Path(root).resolve()),
    "file_count": int(count),
    "sha256": digest,
}
path = Path(output)
path.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
os.chmod(path, 0o600)
PY
    then
        rm -f -- "$temporary"
        return 1
    fi
    mv -f -- "$temporary" "$destination"
}

verify_recorded_nuclei_template_provenance() {
    local provenance="$RUN_DIR/scope/nuclei-template-tree.json"
    [[ -e "$provenance" || -L "$provenance" ]] || return 0
    [[ -f "$provenance" && ! -L "$provenance" ]] || {
        error "Recorded Nuclei template provenance is not a regular file"
        return 1
    }
    local recorded="" template_root="" expected_count="" expected_digest="" current=""
    if ! recorded="$(python3 -I - "$provenance" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    document = json.loads(path.read_text(encoding="utf-8", errors="strict"))
    root = document["directory"]
    count = document["file_count"]
    digest = document["sha256"]
    if not isinstance(root, str) or not Path(root).is_absolute() or any(ch in root for ch in "\t\r\n"):
        raise ValueError("directory is not a safe absolute path")
    if not isinstance(count, int) or count < 0:
        raise ValueError("file_count is invalid")
    if not isinstance(digest, str) or len(digest) != 64 or any(ch not in "0123456789abcdef" for ch in digest):
        raise ValueError("sha256 is invalid")
except (OSError, UnicodeError, KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
    print(f"invalid Nuclei template provenance: {exc}", file=sys.stderr)
    raise SystemExit(1)
print(f"{root}\t{count}\t{digest}")
PY
    )"; then
        return 1
    fi
    IFS=$'\t' read -r template_root expected_count expected_digest <<<"$recorded"
    if ! current="$(hash_nuclei_template_tree "$template_root")"; then
        return 1
    fi
    if [[ "$current" != "$expected_count"$'\t'"$expected_digest" ]]; then
        error "Nuclei template tree changed since its provenance was frozen"
        return 1
    fi
    info "Verified frozen Nuclei template provenance before reusing checkpoints"
}

freeze_active_web_wordlist() {
    local source="$1"
    local destination="$RUN_DIR/scope/gobuster-wordlist.txt"
    local provenance="$RUN_DIR/scope/gobuster-wordlist.json"
    python3 -I - "$source" "$destination" "$provenance" <<'PY'
import hashlib
import json
import os
import stat
import sys
from pathlib import Path

source_input = Path(sys.argv[1])
destination = Path(sys.argv[2])
provenance = Path(sys.argv[3])
maximum = 128 * 1024 * 1024
try:
    source = source_input.resolve(strict=True)
    if destination.exists() and source.samefile(destination):
        raise RuntimeError("source and frozen destination identify the same file")
    descriptor = os.open(source, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
except (OSError, RuntimeError) as exc:
    print(f"could not open active-web wordlist safely: {exc}", file=sys.stderr)
    raise SystemExit(1)

state = destination.parent.parent / ".state"
temporary = state / f"gobuster-wordlist.tmp.{os.getpid()}"
metadata_temporary = state / f"gobuster-wordlist-metadata.tmp.{os.getpid()}"
try:
    before = os.fstat(descriptor)
    if not stat.S_ISREG(before.st_mode) or before.st_size == 0:
        raise RuntimeError("wordlist is not a nonempty regular file")
    if before.st_size > maximum:
        raise RuntimeError(f"wordlist exceeds the {maximum}-byte ceiling")
    digest = hashlib.sha256()
    copied = 0
    with os.fdopen(descriptor, "rb", closefd=True) as input_handle, temporary.open("xb") as output_handle:
        descriptor = -1
        while True:
            block = input_handle.read(1024 * 1024)
            if not block:
                break
            copied += len(block)
            if copied > maximum:
                raise RuntimeError(f"wordlist exceeds the {maximum}-byte ceiling")
            digest.update(block)
            output_handle.write(block)
        output_handle.flush()
        os.fsync(output_handle.fileno())
        after = os.fstat(input_handle.fileno())
    stable_fields = ("st_dev", "st_ino", "st_size", "st_mtime_ns", "st_ctime_ns")
    if any(getattr(before, field) != getattr(after, field) for field in stable_fields):
        raise RuntimeError("wordlist changed while it was being frozen")
    os.chmod(temporary, 0o600)
    document = {
        "bytes": copied,
        "sha256": digest.hexdigest(),
        "source": str(source),
    }
    metadata_temporary.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.chmod(metadata_temporary, 0o600)
    os.replace(temporary, destination)
    os.replace(metadata_temporary, provenance)
except (OSError, RuntimeError) as exc:
    print(f"could not freeze active-web wordlist: {exc}", file=sys.stderr)
    for path in (temporary, metadata_temporary):
        try:
            path.unlink()
        except FileNotFoundError:
            pass
    raise SystemExit(1)
finally:
    if descriptor >= 0:
        os.close(descriptor)
print(destination)
PY
}

verify_active_web_wordlist() {
    local wordlist="$RUN_DIR/scope/gobuster-wordlist.txt"
    local provenance="$RUN_DIR/scope/gobuster-wordlist.json"
    python3 -I - "$wordlist" "$provenance" <<'PY'
import hashlib
import json
import os
import stat
import sys
from pathlib import Path

wordlist = Path(sys.argv[1])
provenance = Path(sys.argv[2])
maximum = 128 * 1024 * 1024
try:
    if wordlist.is_symlink() or provenance.is_symlink():
        raise RuntimeError("wordlist or provenance is a symbolic link")
    expected = json.loads(provenance.read_text(encoding="utf-8", errors="strict"))
    descriptor = os.open(wordlist, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    with os.fdopen(descriptor, "rb", closefd=True) as handle:
        before = os.fstat(handle.fileno())
        if not stat.S_ISREG(before.st_mode) or before.st_size > maximum:
            raise RuntimeError("frozen wordlist is not a bounded regular file")
        digest = hashlib.sha256()
        size = 0
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            size += len(block)
            if size > maximum:
                raise RuntimeError("frozen wordlist exceeds the size ceiling")
            digest.update(block)
        after = os.fstat(handle.fileno())
    stable_fields = ("st_dev", "st_ino", "st_size", "st_mtime_ns", "st_ctime_ns")
    if any(getattr(before, field) != getattr(after, field) for field in stable_fields):
        raise RuntimeError("frozen wordlist changed while it was being verified")
    if size != expected.get("bytes") or digest.hexdigest() != expected.get("sha256"):
        raise RuntimeError("frozen wordlist does not match its recorded size and SHA-256")
except (OSError, UnicodeError, ValueError, TypeError, AttributeError, json.JSONDecodeError, RuntimeError) as exc:
    print(f"active-web wordlist verification failed: {exc}", file=sys.stderr)
    raise SystemExit(1)
PY
}

record_active_web_wordlist_drift() {
    local url="$1" position="$2"
    printf '%s\t%s\t%s\t%s\t%s\n' "$(timestamp)" followups \
        "Gobuster wordlist verification $position $url" 65 "scope/gobuster-wordlist.json" \
        >>"$RUN_DIR/logs/errors.tsv"
    append_event followups "Gobuster wordlist verification $position $url" \
        INVALID_OUTPUT 65 0 "scope/gobuster-wordlist.json"
    error "[followups] Frozen Gobuster wordlist drifted $position probing $url"
}

capture_environment() {
    local suffix=""
    (( RESUME_MODE )) && suffix=".resume-$(date -u '+%Y%m%dT%H%M%SZ')-$$"
    {
        printf 'runner_version=%s\n' "$SCRIPT_VERSION"
        printf 'started_utc=%s\n' "$RUN_STARTED_UTC"
        printf 'hostname=%s\n' "$(hostname 2>/dev/null || true)"
        printf 'user=%s\n' "$(id -un)"
        printf 'uid=%s\n' "$EUID"
        printf 'pwd=%s\n' "$PWD"
        printf 'kernel=%s\n' "$(uname -a)"
        if [[ -r /etc/os-release ]]; then
            sed 's/^/os_/' /etc/os-release
        fi
        printf '\ninterfaces:\n'
        ip -br address 2>/dev/null || true
        printf '\nroutes:\n'
        ip route show 2>/dev/null || true
        ip -6 route show 2>/dev/null || true
        printf '\nresolver:\n'
        sed -n '1,120p' /etc/resolv.conf 2>/dev/null || true
    } >"$RUN_DIR/logs/environment${suffix}.txt" || return 1

    {
        local command_name
        for command_name in nmap python3 curl dig smbclient rpcclient ldapsearch snmpwalk \
            rpcinfo showmount ssh-keyscan whatweb nikto gobuster ffuf sslscan \
            ssh-audit nxc netexec enum4linux-ng nuclei httpx httpx-toolkit searchsploit \
            swaks xsltproc; do
            if have "$command_name"; then
                record_tool_provenance "$command_name"
            fi
        done
        if have nuclei; then
            local nuclei_template_dir=""
            nuclei_template_dir="$(find_nuclei_templates || true)"
            if [[ -n "$nuclei_template_dir" ]]; then
                local template_metadata="" template_count="" template_digest=""
                if ! template_metadata="$(hash_nuclei_template_tree "$nuclei_template_dir")"; then
                    printf 'nuclei-templates\t%s\tprovenance=unavailable\n' "$nuclei_template_dir"
                    warn "Could not hash the complete Nuclei template tree for environment provenance"
                else
                    IFS=$'\t' read -r template_count template_digest <<<"$template_metadata"
                    printf 'nuclei-templates\t%s\tfile_count=%s\ttree_sha256=%s\n' \
                        "$nuclei_template_dir" "$template_count" "$template_digest"
                fi
            fi
        fi
    } >"$RUN_DIR/logs/tool-versions${suffix}.txt" || return 1
}

write_initial_scope_files() {
    local requested="$RUN_DIR/scope/requested.txt"
    local excluded="$RUN_DIR/scope/excluded.requested.txt"
    : >"$requested"
    : >"$excluded"
    if [[ -n "$SCOPE_FILE" ]]; then
        [[ -r "$SCOPE_FILE" ]] || die "cannot read scope file: $SCOPE_FILE"
        sed 's/\r$//' "$SCOPE_FILE" >>"$requested"
        # A scope file with no final newline would otherwise glue the first
        # --target onto its last line, losing both.  Blank lines are skipped
        # by the normalizer, so an unconditional separator is safe.
        printf '\n' >>"$requested"
    fi
    local target
    for target in "${TARGET_ARGS[@]}"; do
        printf '%s\n' "$target" >>"$requested"
    done
    [[ -s "$requested" ]] || die "supply --scope FILE or at least one --target"
    if [[ -n "$EXCLUDE_FILE" ]]; then
        [[ -r "$EXCLUDE_FILE" ]] || die "cannot read exclude file: $EXCLUDE_FILE"
        sed 's/\r$//' "$EXCLUDE_FILE" >>"$excluded"
        printf '\n' >>"$excluded"
    fi
}

normalize_scope() {
    local requested="$RUN_DIR/scope/requested.txt"
    local excluded="$RUN_DIR/scope/excluded.requested.txt"
    info "Normalizing and freezing authorized scope"
    python3 -I - "$requested" "$excluded" "$RUN_DIR/scope" "$MAX_ADDRESSES" "$ALLOW_LARGE_SCOPE" <<'PY'
import ipaddress
import json
import re
import socket
import sys
from pathlib import Path

def concise_exception(exception_type, value, traceback):
    if issubclass(exception_type, ValueError):
        print(f"scope error: {value}", file=sys.stderr)
    else:
        sys.__excepthook__(exception_type, value, traceback)

sys.excepthook = concise_exception

requested_path, excluded_path, output_path, max_text, allow_large_text = sys.argv[1:]
out = Path(output_path)
max_addresses = int(max_text)
allow_large = allow_large_text == "1"

hostname_re = re.compile(
    r"^(?=.{1,253}\.?$)(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)*"
    r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.?$"
)

MAPPED_IPV6_SPACE = ipaddress.ip_network("::ffff:0:0/96")

def unmap_ipv4(network):
    # Nmap reaches ::ffff:a.b.c.d as the IPv4 host, but an IPv4 exclusion can
    # never match an IPv6 network, so a mapped entry would silently survive
    # exclusion.  Collapse the mapped range back into real IPv4 networks.
    if network.version != 6 or not network.subnet_of(MAPPED_IPV6_SPACE):
        return network
    return ipaddress.ip_network(
        f"{network.network_address.ipv4_mapped}/{network.prefixlen - 96}", strict=True
    )

def tokens(path):
    values = []
    for number, raw in enumerate(Path(path).read_text(errors="strict").splitlines(), 1):
        value = raw.split("#", 1)[0].strip()
        if not value:
            continue
        if any(ch.isspace() for ch in value):
            raise ValueError(f"{path}:{number}: each line must contain one target")
        if value.startswith("-"):
            raise ValueError(f"{path}:{number}: option-like target rejected: {value}")
        values.append((value, number))
    return values

def resolve_entry(value, source, number):
    if re.fullmatch(r"[0-9.]+-[0-9.]+", value):
        raise ValueError(f"{source}:{number}: Nmap-style address ranges are not accepted; use CIDR notation: {value}")
    try:
        # strict=True so a CIDR carrying host bits is refused outright rather
        # than silently widened to the network that contains it.
        network = unmap_ipv4(ipaddress.ip_network(value, strict=True))
        if network.prefixlen == 0:
            raise ValueError(f"{source}:{number}: default-route scope is not allowed: {value}")
        return [network], [(value, "network", str(network))]
    except ValueError as first_error:
        message = str(first_error)
        if "default-route" in message:
            raise
        if "host bits set" in message:
            widened = ipaddress.ip_network(value, strict=False)
            host = value.split("/", 1)[0]
            raise ValueError(
                f"{source}:{number}: CIDR has host bits set: {value}; write "
                f"{widened} to authorize that whole network, or "
                f"{host}/{widened.max_prefixlen} for just that host"
            ) from first_error
        if "/" in value or not hostname_re.fullmatch(value):
            raise ValueError(f"{source}:{number}: invalid IP, CIDR, or hostname: {value}")
    # Anything still here failed strict address parsing, so it is about to be
    # handed to the resolver.  getaddrinfo() accepts malformed address literals
    # and rewrites them to a DIFFERENT address -- 010.10.10.5 becomes 8.10.10.5,
    # 192.168.1 becomes 192.168.0.1, 2130706433 becomes 127.0.0.1 -- which would
    # freeze an unauthorized, possibly public host as in-scope.  A real hostname
    # has a letter in its last label and no hex literal in any label.
    name_labels = value.rstrip(".").split(".")
    if not re.search(r"[A-Za-z]", name_labels[-1]) or any(
        re.fullmatch(r"0[xX][0-9A-Fa-f]+", label) for label in name_labels
    ):
        raise ValueError(
            f"{source}:{number}: not a valid IP, CIDR, or hostname: {value}; "
            "leading zeros, hex, and short forms are refused because the "
            "resolver would silently rewrite them to a different address"
        )
    name = value.rstrip(".")
    try:
        answers = socket.getaddrinfo(name, None, type=socket.SOCK_STREAM)
    except socket.gaierror as exc:
        raise ValueError(f"{source}:{number}: hostname did not resolve: {value}: {exc}") from exc
    addresses = sorted({item[4][0].split("%", 1)[0] for item in answers})
    if not addresses:
        raise ValueError(f"{source}:{number}: hostname returned no A/AAAA addresses: {value}")
    networks = [
        unmap_ipv4(ipaddress.ip_network(address, strict=False)) for address in addresses
    ]
    rows = [(value, "hostname", str(network.network_address)) for network in networks]
    return networks, rows

def collapse(networks, version):
    return list(ipaddress.collapse_addresses(n for n in networks if n.version == version))

def subtract_one(network, exclusion):
    if network.version != exclusion.version or not network.overlaps(exclusion):
        return [network]
    if network.subnet_of(exclusion):
        return []
    if exclusion.subnet_of(network):
        return list(network.address_exclude(exclusion))
    return [network]

def subtract(networks, exclusions):
    remaining = list(networks)
    for exclusion in exclusions:
        next_remaining = []
        for network in remaining:
            next_remaining.extend(subtract_one(network, exclusion))
        remaining = next_remaining
    # ipaddress.collapse_addresses rejects a mixed IPv4/IPv6 iterable.
    # Keep each address family independent while preserving both families.
    return collapse(remaining, 4) + collapse(remaining, 6)

target_networks, target_rows = [], []
exclude_networks, exclude_rows = [], []
for value, number in tokens(requested_path):
    networks, rows = resolve_entry(value, requested_path, number)
    target_networks.extend(networks)
    target_rows.extend(rows)
for value, number in tokens(excluded_path):
    networks, rows = resolve_entry(value, excluded_path, number)
    exclude_networks.extend(networks)
    exclude_rows.extend(rows)

if not target_networks:
    raise ValueError("scope is empty")

targets = collapse(target_networks, 4) + collapse(target_networks, 6)
excludes = collapse(exclude_networks, 4) + collapse(exclude_networks, 6)
effective = subtract(targets, excludes)
if not effective:
    raise ValueError("all targets were removed by exclusions")

for network in effective:
    if network.version == 6 and network.num_addresses > 256 and not allow_large:
        raise ValueError(f"IPv6 network {network} is broader than /120; use --allow-large-scope only if the ROE permits it")
count = sum(network.num_addresses for network in effective)
if count > max_addresses and not allow_large:
    raise ValueError(
        f"effective scope contains {count} addresses, above the ceiling of {max_addresses}; "
        "use --allow-large-scope only after checking the ROE"
    )

def write_lines(name, values):
    text = "".join(f"{value}\n" for value in values)
    (out / name).write_text(text)

effective4 = sorted((n for n in effective if n.version == 4), key=lambda n: (int(n.network_address), n.prefixlen))
effective6 = sorted((n for n in effective if n.version == 6), key=lambda n: (int(n.network_address), n.prefixlen))
exclude4 = sorted((n for n in excludes if n.version == 4), key=lambda n: (int(n.network_address), n.prefixlen))
exclude6 = sorted((n for n in excludes if n.version == 6), key=lambda n: (int(n.network_address), n.prefixlen))
write_lines("targets.ipv4.txt", effective4)
write_lines("targets.ipv6.txt", effective6)
write_lines("excludes.ipv4.txt", exclude4)
write_lines("excludes.ipv6.txt", exclude6)

with (out / "resolution.tsv").open("w") as handle:
    handle.write("source\tkind\tresolved\tdisposition\n")
    for source, kind, resolved in target_rows:
        handle.write(f"{source}\t{kind}\t{resolved}\ttarget\n")
    for source, kind, resolved in exclude_rows:
        handle.write(f"{source}\t{kind}\t{resolved}\texclude\n")

document = {
    "address_count": count,
    "ipv4_networks": [str(n) for n in effective4],
    "ipv6_networks": [str(n) for n in effective6],
    "excluded_networks": [str(n) for n in excludes],
}
(out / "allowed.json").write_text(json.dumps(document, indent=2, sort_keys=True) + "\n")
(out / "address-count.txt").write_text(f"{count}\n")
print(f"Frozen effective scope: {count} addresses ({len(effective4)} IPv4 networks, {len(effective6)} IPv6 networks)")
PY
    (
        cd -- "$RUN_DIR/scope"
        sha256sum requested.txt excluded.requested.txt \
            targets.ipv4.txt targets.ipv6.txt excludes.ipv4.txt excludes.ipv6.txt \
            resolution.tsv allowed.json address-count.txt >SHA256SUMS
    )
    ok "Scope contains $(<"$RUN_DIR/scope/address-count.txt") authorized address(es) after exclusions"
}

verify_frozen_scope() {
    local scope_dir="$RUN_DIR/scope" required
    for required in requested.txt excluded.requested.txt targets.ipv4.txt targets.ipv6.txt \
        excludes.ipv4.txt excludes.ipv6.txt resolution.tsv allowed.json address-count.txt SHA256SUMS; do
        [[ -f "$scope_dir/$required" && ! -L "$scope_dir/$required" && -r "$scope_dir/$required" ]] \
            || die "resume scope is incomplete or unsafe: scope/$required must be a regular file"
    done
    info "Verifying frozen scope before resume"
    if ! (cd -- "$scope_dir" && sha256sum --check --strict SHA256SUMS); then
        die "frozen scope verification failed; start a new run rather than resuming altered scope artifacts"
    fi
    ok "Frozen scope verified; resume will not resolve hostnames again"
}

verify_artifact_manifest() {
    local manifest="$RUN_DIR/reports/SHA256SUMS"
    [[ -r "$manifest" ]] || return 2
    info "Verifying the prior raw, normalized, scope, and report artifacts"
    python3 -I - "$RUN_DIR" <<'PY'
import hashlib
import re
import sys
from pathlib import Path

run_dir = Path(sys.argv[1]).resolve()
manifest = run_dir / "reports" / "SHA256SUMS"
line_pattern = re.compile(r"^([0-9a-fA-F]{64})  (.+)$")
expected = {}
problems = []

if manifest.is_symlink():
    print("Artifact manifest must not be a symbolic link", file=sys.stderr)
    raise SystemExit(1)

try:
    lines = manifest.read_text(encoding="utf-8", errors="strict").splitlines()
except (OSError, UnicodeError) as exc:
    print(f"Artifact manifest could not be read: {exc}", file=sys.stderr)
    raise SystemExit(1)

for number, line in enumerate(lines, 1):
    match = line_pattern.fullmatch(line)
    if not match:
        problems.append(f"malformed manifest line {number}")
        continue
    digest, relative_text = match.groups()
    relative = Path(relative_text)
    if relative.is_absolute() or ".." in relative.parts:
        problems.append(f"unsafe manifest path on line {number}: {relative_text}")
        continue
    key = relative.as_posix()
    if key in expected:
        problems.append(f"duplicate manifest path on line {number}: {key}")
        continue
    expected[key] = digest.lower()

if not expected:
    problems.append("artifact manifest contains no entries")

actual = {}
for directory in ("scope", "raw", "targets", "reports"):
    root = run_dir / directory
    if root.is_symlink():
        problems.append(f"covered artifact root is a symbolic link: {directory}")
        continue
    if not root.exists():
        continue
    if not root.is_dir():
        problems.append(f"covered artifact root is not a directory: {directory}")
        continue
    for path in sorted(root.rglob("*")):
        if path == manifest:
            continue
        if path.is_symlink():
            problems.append(f"symbolic links are not allowed in covered artifacts: {path.relative_to(run_dir)}")
            continue
        if path.is_dir():
            continue
        if not path.is_file():
            problems.append(f"unsupported file type in covered artifacts: {path.relative_to(run_dir)}")
            continue
        try:
            resolved = path.resolve()
            resolved.relative_to(run_dir)
        except (OSError, ValueError):
            problems.append(f"artifact path escapes the run directory: {path}")
            continue
        actual[path.relative_to(run_dir).as_posix()] = path

for key in sorted(set(expected) - set(actual)):
    problems.append(f"listed artifact is missing: {key}")
for key in sorted(set(actual) - set(expected)):
    problems.append(f"unlisted artifact is present: {key}")

verified = 0
for key in sorted(set(expected) & set(actual)):
    digest = hashlib.sha256()
    try:
        with actual[key].open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
    except OSError as exc:
        problems.append(f"could not hash {key}: {exc}")
        continue
    received = digest.hexdigest()
    if received != expected[key]:
        problems.append(f"artifact hash mismatch: {key}")
    else:
        verified += 1
        print(f"{key}: OK")

if problems:
    for problem in problems:
        print(f"artifact integrity error: {problem}", file=sys.stderr)
    raise SystemExit(1)
print(f"Verified {verified} artifact(s) with a complete path inventory.")
PY
}

retire_verified_artifact_manifest() {
    local manifest="$RUN_DIR/reports/SHA256SUMS"
    [[ -f "$manifest" && ! -L "$manifest" ]] \
        || die "internal error: the verified artifact manifest is no longer a regular file"
    local history_root="$RUN_DIR/.state/manifest-history"
    local history_dir resolved_run resolved_history
    if [[ ! -d "$RUN_DIR/.state" || -L "$RUN_DIR/.state" || -L "$history_root" ]]; then
        die "manifest history path must use real directories inside this run"
    fi
    mkdir -p -- "$history_root" || die "could not create manifest history root"
    resolved_run="$(readlink -f -- "$RUN_DIR")" \
        || die "could not resolve the run directory"
    resolved_history="$(readlink -f -- "$history_root")" \
        || die "could not resolve the manifest history root"
    [[ "$resolved_history" == "$resolved_run/.state/manifest-history" ]] \
        || die "manifest history path resolves outside its fixed run location"
    history_dir="$history_root/$(date -u '+%Y%m%dT%H%M%SZ')-$$-$RANDOM"
    mkdir -- "$history_dir" || die "could not create unique manifest history directory"
    mv -- "$manifest" "$history_dir/SHA256SUMS" \
        || die "could not retire the verified artifact manifest"
    ok "Retired the verified artifact manifest to ${history_dir#"$RUN_DIR"/}/SHA256SUMS before mutable work"
}

invalidate_all_phase_checkpoints() {
    local marker count=0
    for marker in "$RUN_DIR"/.state/*.done; do
        [[ -e "$marker" ]] || continue
        rm -f -- "$marker"
        count=$((count + 1))
    done
    warn "No completed artifact manifest was available; invalidated $count phase checkpoint(s) so interrupted evidence is rebuilt"
}

reset_interrupted_current_evidence() {
    # With no completed manifest there is no trustworthy boundary between
    # current and interrupted output. Preserve it as history before any phase
    # is allowed to derive targets from root-level evidence.
    local -a raw_files=() target_files=() report_files=()
    mapfile -d '' -t raw_files < <(
        find "$RUN_DIR/raw" -mindepth 1 -maxdepth 1 -type f ! -name '*.log' -print0
    )
    mapfile -d '' -t target_files < <(
        find "$RUN_DIR/targets" -mindepth 1 -maxdepth 1 -type f -print0
    )
    mapfile -d '' -t report_files < <(
        find "$RUN_DIR/reports" -mindepth 1 -maxdepth 1 -type f -print0
    )
    archive_evidence_files "interrupted-current-raw" "${raw_files[@]}" || return 1
    archive_evidence_files "interrupted-current-targets" "${target_files[@]}" || return 1
    archive_evidence_files "interrupted-current-reports" "${report_files[@]}" || return 1
    info "Retired unverified current evidence before rebuilding the interrupted run"
}

save_run_settings() {
    printf '%s\n' "$PROFILE" >"$RUN_DIR/.state/profile"
    printf '%s\n' "$DOMAIN" >"$RUN_DIR/.state/domain"
    printf '%s\n' "$INTERFACE" >"$RUN_DIR/.state/interface"
    printf '%s\n' "$PHASES" >"$RUN_DIR/.state/phases"
    printf '%s\n' "$UDP_ENABLED" >"$RUN_DIR/.state/udp_enabled"
    printf '%s\n' "$ACTIVE_WEB" >"$RUN_DIR/.state/active_web"
    printf '%s\n' "$VULN_ENABLED" >"$RUN_DIR/.state/vuln_enabled"
    printf '%s\n' "$MAX_RATE" >"$RUN_DIR/.state/max_rate"
    printf '%s\n' "$MIN_RATE" >"$RUN_DIR/.state/min_rate"
    printf '%s\n' "$MAX_RETRIES" >"$RUN_DIR/.state/max_retries"
    printf '%s\n' "$HOST_TIMEOUT" >"$RUN_DIR/.state/host_timeout"
    printf '%s\n' "$COMMAND_TIMEOUT" >"$RUN_DIR/.state/command_timeout"
    printf '%s\n' "$MAX_FOLLOWUPS" >"$RUN_DIR/.state/max_followups"
    printf '%s\n' "$JOBS" >"$RUN_DIR/.state/jobs"
    if [[ -n "$SNMP_COMMUNITY_FILE" ]]; then
        printf '1\n' >"$RUN_DIR/.state/custom_snmp_required"
    else
        printf '0\n' >"$RUN_DIR/.state/custom_snmp_required"
    fi
    (
        cd -- "$RUN_DIR/.state"
        local temporary="settings.SHA256SUMS.tmp.$$"
        sha256sum profile domain interface phases udp_enabled active_web vuln_enabled \
            max_rate min_rate max_retries host_timeout command_timeout max_followups jobs \
            custom_snmp_required >"$temporary"
        mv -f -- "$temporary" settings.SHA256SUMS
    )
}

verify_resume_settings() {
    local state_dir="$RUN_DIR/.state" required
    local -a setting_files=(
        profile domain interface phases udp_enabled active_web vuln_enabled
        max_rate min_rate max_retries host_timeout command_timeout max_followups jobs
        custom_snmp_required settings.SHA256SUMS
    )
    for required in "${setting_files[@]}"; do
        [[ -f "$state_dir/$required" && ! -L "$state_dir/$required" && -r "$state_dir/$required" ]] \
            || die "resume settings are incomplete or unsafe: .state/$required must be a regular file"
    done
    info "Verifying immutable resume settings"
    if ! (cd -- "$state_dir" && sha256sum --check --strict settings.SHA256SUMS); then
        die "resume settings verification failed; start a new run rather than trusting altered settings"
    fi
    ok "Immutable resume settings verified"
}

phase_requested() { [[ ",$PHASES," == *",$1,"* ]]; }

phase_done() { [[ -f "$RUN_DIR/.state/$1.done" ]]; }

mark_phase_done() {
    local phase="$1"
    local temporary="$RUN_DIR/.state/${phase}.done.tmp"
    printf '%s\n' "$(timestamp)" >"$temporary" || return 1
    mv -f -- "$temporary" "$RUN_DIR/.state/${phase}.done" || return 1
}

invalidate_downstream_phases() {
    local phase="$1" downstream
    local -a phases=()
    case "$phase" in
        discovery) phases=(tcp udp services followups vuln report) ;;
        tcp) phases=(udp services followups vuln report) ;;
        udp) phases=(services followups vuln report) ;;
        services) phases=(followups vuln report) ;;
        followups) phases=(vuln report) ;;
        vuln) phases=(report) ;;
        report) phases=() ;;
    esac
    for downstream in "${phases[@]}"; do
        if [[ -f "$RUN_DIR/.state/$downstream.done" ]]; then
            rm -f -- "$RUN_DIR/.state/$downstream.done"
            info "[$phase] invalidated downstream checkpoint: $downstream"
        fi
    done
}

write_nmap_data_snapshot() {
    local data_root="$1" nmap_binary="$2" output="$3"
    shift 3
    python3 -I - "$data_root" "$nmap_binary" "$output" "$@" <<'PY'
import hashlib
import json
import os
import pwd
import stat
import sys
from pathlib import Path

root = Path(sys.argv[1])
binary = Path(sys.argv[2])
output = Path(sys.argv[3])
selected_scripts = sorted(set(sys.argv[4:]))

def reject(message):
    print(message, file=sys.stderr)
    raise SystemExit(1)

def regular_file_record(path):
    try:
        descriptor = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    except OSError as exc:
        reject(f"could not open Nmap input safely: {path}: {exc}")
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            reject(f"Nmap input is not a regular file: {path}")
        if before.st_uid not in {0, os.geteuid()} or before.st_mode & 0o6022:
            reject(f"Nmap input has unsafe ownership, write permissions, or set-id bits: {path}")
        digest = hashlib.sha256()
        length = 0
        with os.fdopen(descriptor, "rb", closefd=False) as handle:
            for block in iter(lambda: handle.read(1024 * 1024), b""):
                length += len(block)
                digest.update(block)
        after = os.fstat(descriptor)
        stable = ("st_dev", "st_ino", "st_size", "st_mtime_ns", "st_ctime_ns")
        if any(getattr(before, field) != getattr(after, field) for field in stable):
            reject(f"Nmap input changed while it was hashed: {path}")
        return length, digest.hexdigest()
    finally:
        os.close(descriptor)

def inventory_tree():
    try:
        root_stat = os.lstat(root)
    except OSError as exc:
        reject(f"could not inspect Nmap data root {root}: {exc}")
    if not stat.S_ISDIR(root_stat.st_mode) or stat.S_ISLNK(root_stat.st_mode):
        reject(f"Nmap data root is not a real directory: {root}")
    if root_stat.st_uid not in {0, os.geteuid()} or root_stat.st_mode & 0o022:
        reject(f"Nmap data root has unsafe ownership or write permissions: {root}")
    entries = [("D", ".", root)]
    pending = [root]
    while pending:
        directory = pending.pop()
        try:
            children = sorted(os.scandir(directory), key=lambda item: item.name)
        except OSError as exc:
            reject(f"could not enumerate Nmap data directory {directory}: {exc}")
        for child in children:
            path = Path(child.path)
            relative = path.relative_to(root).as_posix()
            try:
                item_stat = child.stat(follow_symlinks=False)
            except OSError as exc:
                reject(f"could not inspect Nmap data path {relative}: {exc}")
            if stat.S_ISLNK(item_stat.st_mode):
                reject(f"Nmap data tree contains a symbolic link: {relative}")
            if stat.S_ISDIR(item_stat.st_mode):
                if item_stat.st_uid not in {0, os.geteuid()} or item_stat.st_mode & 0o022:
                    reject(f"Nmap data directory has unsafe ownership or write permissions: {relative}")
                entries.append(("D", relative, path))
                pending.append(path)
            elif stat.S_ISREG(item_stat.st_mode):
                if item_stat.st_uid not in {0, os.geteuid()} or item_stat.st_mode & 0o6022:
                    reject(f"Nmap data file has unsafe ownership, write permissions, or set-id bits: {relative}")
                entries.append(("F", relative, path))
            else:
                reject(f"Nmap data tree contains an unsupported path: {relative}")
    return sorted(entries, key=lambda item: (item[1], item[0]))

initial = inventory_tree()
records = []
tree_digest = hashlib.sha256()
total = 0
files = 0
directories = 0
for kind, relative, path in initial:
    relative_bytes = relative.encode("utf-8")
    tree_digest.update(kind.encode("ascii"))
    tree_digest.update(len(relative_bytes).to_bytes(4, "big"))
    tree_digest.update(relative_bytes)
    if kind == "D":
        directories += 1
        records.append({"path": relative, "type": "directory"})
        continue
    length, file_digest = regular_file_record(path)
    tree_digest.update(length.to_bytes(8, "big"))
    tree_digest.update(bytes.fromhex(file_digest))
    total += length
    files += 1
    records.append({"bytes": length, "path": relative, "sha256": file_digest, "type": "file"})

final = inventory_tree()
if [(kind, relative) for kind, relative, _ in initial] != [(kind, relative) for kind, relative, _ in final]:
    reject(f"Nmap data tree changed while it was inventoried: {root}")

binary_length, binary_digest = regular_file_record(binary)
user_paths = []
for uid in sorted({os.getuid(), os.geteuid()}):
    try:
        home_text = pwd.getpwuid(uid).pw_dir
    except KeyError:
        reject(f"could not determine the passwd home for Nmap uid {uid}")
    if not home_text or not os.path.isabs(home_text) or any(ch in home_text for ch in "\0\r\n"):
        reject(f"passwd home is not a safe absolute path for Nmap uid {uid}: {home_text!r}")
    home = Path(home_text)
    try:
        canonical_home = str(home.resolve(strict=True))
        home_stat = os.lstat(home)
    except (OSError, RuntimeError) as exc:
        reject(f"could not resolve the passwd home for Nmap uid {uid}: {home}: {exc}")
    if canonical_home != home_text or stat.S_ISLNK(home_stat.st_mode) or not stat.S_ISDIR(home_stat.st_mode):
        reject(f"passwd home is not a canonical real directory for Nmap uid {uid}: {home}")
    if home_stat.st_uid != uid or home_stat.st_mode & 0o022:
        reject(f"passwd home has unsafe ownership or write permissions for Nmap uid {uid}: {home}")
    user_paths.append({"path": str(home / ".nmap"), "uid": uid})

document = {
    "ambient_user_data_paths": user_paths,
    "directory": str(root),
    "directory_count": directories,
    "file_count": files,
    "nmap_executable": str(binary),
    "nmap_executable_bytes": binary_length,
    "nmap_executable_sha256": binary_digest,
    "schema_version": 2,
    "selected_nse_scripts": selected_scripts,
    "sha256": tree_digest.hexdigest(),
    "total_bytes": total,
}
output.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
os.chmod(output, 0o600)
PY
}

resolve_nmap_binary() {
    local resolved=""
    resolved="$(command -v nmap 2>/dev/null)" || return 1
    resolved="$(readlink -f -- "$resolved")" || return 1
    [[ -f "$resolved" && ! -L "$resolved" && -x "$resolved" ]] || {
        error "Nmap executable is not a real executable file: $resolved"
        return 1
    }
    NMAP_BINARY="$resolved"
}

validate_nmap_ambient_user_data() {
    python3 -I - <<'PY'
import os
import pwd
import stat
import sys
from pathlib import Path

def reject(message):
    print(f"unsafe ambient Nmap user data: {message}", file=sys.stderr)
    raise SystemExit(1)

for uid in sorted({os.getuid(), os.geteuid()}):
    try:
        home_text = pwd.getpwuid(uid).pw_dir
    except KeyError:
        reject(f"passwd has no home for uid {uid}")
    if not home_text or not os.path.isabs(home_text) or any(ch in home_text for ch in "\0\r\n"):
        reject(f"passwd home is not a safe absolute path for uid {uid}: {home_text!r}")
    home = Path(home_text)
    try:
        canonical_home = str(home.resolve(strict=True))
        home_stat = os.lstat(home)
    except (OSError, RuntimeError) as exc:
        reject(f"could not resolve or inspect home {home}: {exc}")
    if canonical_home != home_text or stat.S_ISLNK(home_stat.st_mode) or not stat.S_ISDIR(home_stat.st_mode):
        reject(f"home is not a canonical real directory for uid {uid}: {home}")
    if home_stat.st_uid != uid or home_stat.st_mode & 0o022:
        reject(f"home has unsafe ownership or write permissions for uid {uid}: {home}")
    ambient = home / ".nmap"
    try:
        ambient_stat = os.lstat(ambient)
    except FileNotFoundError:
        continue
    except OSError as exc:
        reject(f"could not inspect {ambient}: {exc}")
    if stat.S_ISLNK(ambient_stat.st_mode) or not stat.S_ISDIR(ambient_stat.st_mode):
        reject(f"path is not a real directory: {ambient}")
    if ambient_stat.st_uid != uid or ambient_stat.st_mode & 0o022:
        reject(f"directory has unsafe ownership or write permissions: {ambient}")
    try:
        first_entry = next(os.scandir(ambient), None)
    except OSError as exc:
        reject(f"could not enumerate {ambient}: {exc}")
    if first_entry is not None:
        reject(f"directory is nonempty and could supply fallback files: {ambient}")
PY
}

validate_nmap_data_layout() {
    local data_root="$1" relative script_name script_path
    [[ -d "$data_root" && ! -L "$data_root" && "$data_root" != *','* \
        && "$data_root" != *$'\n'* && "$data_root" != *$'\r'* ]] || {
        error "Nmap data root is not a safe real directory: $data_root"
        return 1
    }
    for relative in "${NMAP_REQUIRED_DATA_FILES[@]}"; do
        [[ -f "$data_root/$relative" && ! -L "$data_root/$relative" && -s "$data_root/$relative" ]] || {
            error "Required Nmap data file is missing, empty, or unsafe: $data_root/$relative"
            return 1
        }
    done
    for relative in scripts nselib; do
        [[ -d "$data_root/$relative" && ! -L "$data_root/$relative" ]] || {
            error "Required Nmap data directory is missing or unsafe: $data_root/$relative"
            return 1
        }
    done
    find "$data_root/nselib" -type f -print -quit | grep -q . || {
        error "Required Nmap nselib directory is empty: $data_root/nselib"
        return 1
    }
    for script_name in "${NMAP_ALL_NSE_NAMES[@]}"; do
        [[ "$script_name" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || return 1
        script_path="$data_root/scripts/$script_name.nse"
        [[ -f "$script_path" && ! -L "$script_path" && -s "$script_path" ]] || {
            error "Required selected NSE script is missing, empty, or unsafe: $script_path"
            return 1
        }
    done
}

canonical_nmap_adjacent_data_directory() {
    local candidate canonical=""
    [[ -n "$NMAP_BINARY" && "$NMAP_BINARY" == /* ]] || return 1
    candidate="${NMAP_BINARY%/*}/../share/nmap"
    canonical="$(readlink -f -- "$candidate" 2>/dev/null)" || {
        error "Could not resolve Nmap's executable-adjacent data directory: $candidate"
        return 1
    }
    [[ -d "$canonical" && ! -L "$canonical" ]] || {
        error "Nmap's executable-adjacent data directory is unavailable or unsafe: $canonical"
        return 1
    }
    printf '%s\n' "$canonical"
}

select_nmap_data_directory() {
    local canonical=""
    canonical="$(canonical_nmap_adjacent_data_directory)" || return 1
    if ! validate_nmap_data_layout "$canonical"; then
        error "Nmap's executable-adjacent data directory is incomplete or unsafe: $canonical"
        return 1
    fi
    printf '%s\n' "$canonical"
}

build_absolute_nse_list() {
    local data_root="$1" output_name="$2"
    shift 2
    local name path joined=""
    [[ "$output_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1
    for name in "$@"; do
        path="$data_root/scripts/$name.nse"
        [[ -f "$path" && ! -L "$path" && "$path" != *','* ]] || return 1
        [[ -z "$joined" ]] && joined="$path" || joined+=",$path"
    done
    printf -v "$output_name" '%s' "$joined"
}

prepare_nmap_process_isolation() {
    local isolation_root="$RUN_DIR/.state/nmap-process-environment" directory resolved_root resolved_directory
    [[ ! -L "$isolation_root" ]] || die "Nmap process-isolation root must not be a symbolic link"
    mkdir -p -- "$isolation_root"/{home,xdg-config,xdg-data,cwd} \
        || die "could not create Nmap process-isolation directories"
    chmod 700 -- "$isolation_root" "$isolation_root"/{home,xdg-config,xdg-data,cwd}
    resolved_root="$(readlink -f -- "$isolation_root")" || die "could not resolve Nmap isolation root"
    [[ "$resolved_root" == "$(readlink -f -- "$RUN_DIR")/.state/nmap-process-environment" ]] \
        || die "Nmap process-isolation root escaped the run directory"
    for directory in home xdg-config xdg-data cwd; do
        [[ -d "$isolation_root/$directory" && ! -L "$isolation_root/$directory" ]] \
            || die "Nmap process-isolation path is unsafe: $isolation_root/$directory"
        resolved_directory="$(readlink -f -- "$isolation_root/$directory")" || die "could not resolve Nmap isolation path"
        [[ "$resolved_directory" == "$resolved_root/$directory" ]] \
            || die "Nmap process-isolation path escaped its root"
    done
    NMAP_PROCESS_HOME="$isolation_root/home"
    NMAP_PROCESS_XDG_CONFIG="$isolation_root/xdg-config"
    NMAP_PROCESS_XDG_DATA="$isolation_root/xdg-data"
    NMAP_PROCESS_CWD="$isolation_root/cwd"
}

validate_nmap_process_environment() {
    validate_nmap_ambient_user_data || return 1
    local directory
    for directory in "$NMAP_PROCESS_HOME" "$NMAP_PROCESS_XDG_CONFIG" \
        "$NMAP_PROCESS_XDG_DATA" "$NMAP_PROCESS_CWD"; do
        [[ -n "$directory" && -d "$directory" && ! -L "$directory" ]] || {
            error "Nmap process-isolation directory is unavailable or unsafe: $directory"
            return 1
        }
        if find "$directory" -mindepth 1 -print -quit | grep -q .; then
            error "Nmap process-isolation directory is no longer empty: $directory"
            return 1
        fi
    done
}

read_recorded_nmap_directory() {
    local metadata="$RUN_DIR/scope/nmap-data.json"
    [[ -f "$metadata" && ! -L "$metadata" ]] || return 1
    python3 -I - "$metadata" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    document = json.loads(path.read_text(encoding="utf-8", errors="strict"))
    directory = document["directory"]
    if not isinstance(directory, str) or not Path(directory).is_absolute() or any(ch in directory for ch in "\t\r\n"):
        raise ValueError("directory is not a safe absolute path")
except (OSError, UnicodeError, KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
    print(f"invalid Nmap data provenance: {exc}", file=sys.stderr)
    raise SystemExit(1)
print(directory)
PY
}

validate_recorded_nmap_directory() {
    local recorded="$1" expected=""
    [[ -n "$NMAP_BINARY" ]] || return 1
    expected="$(canonical_nmap_adjacent_data_directory)" || return 1
    [[ "$recorded" == "$expected" ]] || {
        error "Recorded Nmap data directory is not the current executable-adjacent directory: $recorded (expected $expected)"
        return 1
    }
}

preflight_recorded_nmap_runtime() {
    (( DRY_RUN )) && return 0
    local metadata="$RUN_DIR/scope/nmap-data.json"
    local recorded="" temporary=""
    resolve_nmap_binary || { error "Could not resolve the Nmap executable"; return 1; }
    env --help 2>&1 | grep -q -- '--chdir' || {
        error "The installed env command cannot isolate Nmap's working directory"
        return 1
    }
    validate_nmap_ambient_user_data || return 1
    if [[ -e "$metadata" || -L "$metadata" ]]; then
        recorded="$(read_recorded_nmap_directory)" || return 1
        validate_recorded_nmap_directory "$recorded" || return 1
    else
        recorded="$(select_nmap_data_directory)" || true
        [[ -n "$recorded" ]] || {
            error "Could not preflight a complete system Nmap data directory"
            return 1
        }
    fi
    validate_nmap_data_layout "$recorded" || return 1
    temporary="$(mktemp --tmpdir cptc-nmap-data.XXXXXXXXXX)" || return 1
    if ! write_nmap_data_snapshot "$recorded" "$NMAP_BINARY" "$temporary" \
        "${NMAP_ALL_NSE_NAMES[@]}"; then
        rm -f -- "$temporary"
        return 1
    fi
    validate_nmap_ambient_user_data || { rm -f -- "$temporary"; return 1; }
    if [[ -e "$metadata" || -L "$metadata" ]] && ! cmp -s -- "$metadata" "$temporary"; then
        rm -f -- "$temporary"
        error "System Nmap data changed since this run was frozen"
        return 1
    fi
    rm -f -- "$temporary"
    NMAP_DATA_DIR="$recorded"
    info "Preflighted system Nmap data before reusing checkpoints"
}

verify_nmap_runtime() {
    (( DRY_RUN )) && return 0
    local metadata="$RUN_DIR/scope/nmap-data.json"
    local temporary="$RUN_DIR/.state/nmap-data.verify.$$.$RANDOM"
    [[ -n "$NMAP_DATA_DIR" && -n "$NMAP_BINARY" && -f "$metadata" && ! -L "$metadata" ]] || {
        error "Nmap runtime provenance is unavailable or unsafe"
        return 1
    }
    validate_nmap_data_layout "$NMAP_DATA_DIR" || return 1
    validate_nmap_process_environment || return 1
    if ! write_nmap_data_snapshot "$NMAP_DATA_DIR" "$NMAP_BINARY" "$temporary" \
        "${NMAP_ALL_NSE_NAMES[@]}"; then
        rm -f -- "$temporary"
        error "Could not revalidate the pinned Nmap data directory"
        return 1
    fi
    if ! cmp -s -- "$metadata" "$temporary"; then
        rm -f -- "$temporary"
        error "Pinned Nmap data changed during this run"
        return 1
    fi
    rm -f -- "$temporary"
    validate_nmap_process_environment || return 1
}

prepare_nmap_runtime() {
    (( DRY_RUN )) && return 0
    local resolved="" metadata="$RUN_DIR/scope/nmap-data.json"
    local temporary="$RUN_DIR/.state/nmap-data.prepare.$$.$RANDOM"
    resolve_nmap_binary || die "could not resolve the Nmap executable"
    env --help 2>&1 | grep -q -- '--chdir' \
        || die "the installed env command does not support --chdir for Nmap process isolation"
    validate_nmap_ambient_user_data \
        || die "ambient Nmap user data must be removed or moved aside before scanning"
    if [[ -e "$metadata" || -L "$metadata" ]]; then
        resolved="$(read_recorded_nmap_directory)" \
            || die "could not read the frozen Nmap data provenance"
        validate_recorded_nmap_directory "$resolved" \
            || die "frozen Nmap data provenance is no longer valid"
    else
        resolved="$(select_nmap_data_directory)" || true
    fi
    [[ -n "$resolved" ]] \
        || die "could not find a complete executable-adjacent Nmap data directory"
    validate_nmap_data_layout "$resolved" \
        || die "the selected system Nmap data directory is incomplete or unsafe"
    prepare_nmap_process_isolation
    validate_nmap_process_environment \
        || die "Nmap process environment could not be isolated"
    build_absolute_nse_list "$resolved" NMAP_SERVICE_NSE_SCRIPTS \
        "${NMAP_SERVICE_NSE_NAMES[@]}" || die "could not bind the service NSE list to absolute paths"
    build_absolute_nse_list "$resolved" NMAP_VULN_NSE_SCRIPTS \
        "${NMAP_VULN_NSE_NAMES[@]}" || die "could not bind the vulnerability NSE list to absolute paths"

    if ! write_nmap_data_snapshot "$resolved" "$NMAP_BINARY" "$temporary" \
        "${NMAP_ALL_NSE_NAMES[@]}"; then
        rm -f -- "$temporary"
        die "could not validate and hash the selected Nmap data directory"
    fi
    if [[ -e "$metadata" || -L "$metadata" ]]; then
        [[ -f "$metadata" && ! -L "$metadata" ]] \
            || die "Nmap data provenance path is not a regular file"
        if ! cmp -s -- "$metadata" "$temporary"; then
            rm -f -- "$temporary"
            die "system Nmap data changed since this run was frozen; start a new run"
        fi
        rm -f -- "$temporary"
    else
        mv -- "$temporary" "$metadata" \
            || die "could not persist Nmap data provenance"
        (
            cd -- "$RUN_DIR/scope"
            sha256sum nmap-data.json >>SHA256SUMS
        ) || die "could not add Nmap data provenance to the frozen scope manifest"
    fi
    NMAP_DATA_DIR="$resolved"
    info "Pinned Nmap executable and complete data tree: $NMAP_BINARY / $NMAP_DATA_DIR"
}

build_nmap_base() {
    # build_nmap_base ARRAY_NAME FAMILY TARGET_FILE OUTPUT_PREFIX
    local -n output_array="$1"
    local family="$2" target_file="$3" output_prefix="$4"
    local nmap_command="${NMAP_BINARY:-nmap}"
    # NMAP_ARGS is injected into Nmap's own argv, so leaving it set lets the
    # ambient environment add targets outside the frozen scope and load NSE
    # outside the vetted list.  It must be scrubbed like the rest.
    output_array=(env -u NMAPDIR -u NMAP_ARGS -u NMAP_PRIVILEGED -u NMAP_UNPRIVILEGED \
        -u LUA_PATH -u LUA_CPATH)
    if [[ -n "$NMAP_PROCESS_CWD" ]]; then
        output_array+=(--chdir="$NMAP_PROCESS_CWD" \
            HOME="$NMAP_PROCESS_HOME" XDG_CONFIG_HOME="$NMAP_PROCESS_XDG_CONFIG" \
            XDG_DATA_HOME="$NMAP_PROCESS_XDG_DATA")
    fi
    output_array+=("$nmap_command" -vv --reason --stats-every 30s -n \
        -iL "$target_file" -oA "$output_prefix")
    if [[ -n "$NMAP_DATA_DIR" ]]; then
        output_array+=(--datadir "$NMAP_DATA_DIR" \
            --versiondb "$NMAP_DATA_DIR/nmap-service-probes" \
            --stylesheet "$NMAP_DATA_DIR/nmap.xsl")
    fi
    [[ "$family" == 6 ]] && output_array+=(-6)
    [[ -n "$INTERFACE" ]] && output_array+=(-e "$INTERFACE")
    (( MAX_RATE > 0 )) && output_array+=(--max-rate "$MAX_RATE")
    (( MIN_RATE > 0 )) && output_array+=(--min-rate "$MIN_RATE")
    output_array+=(--max-retries "$MAX_RETRIES" --host-timeout "$HOST_TIMEOUT")
}

run_nmap_family() {
    # run_nmap_family PHASE NAME FAMILY TARGET_FILE OUTPUT_PREFIX EXTRA...
    local phase="$1" name="$2" family="$3" target_file="$4" prefix="$5"
    shift 5
    if (( DRY_RUN == 0 )); then
        archive_evidence_files "${phase}-${name}-prior" \
            "${prefix}.xml" "${prefix}.nmap" "${prefix}.gnmap" || return 1
    fi
    if (( DRY_RUN == 0 )) && [[ -s "$target_file" ]]; then
        if ! verify_nmap_runtime; then
            printf '%s\t%s\t%s\t%s\t%s\n' "$(timestamp)" "$phase" \
                "Nmap data verification before $name" 65 "scope/nmap-data.json" \
                >>"$RUN_DIR/logs/errors.tsv"
            append_event "$phase" "Nmap data verification before $name" \
                INVALID_OUTPUT 65 0 "scope/nmap-data.json"
            return 65
        fi
    fi
    [[ -s "$target_file" ]] || { record_skip "$phase" "$name" "no IPv${family} targets"; return 0; }
    local -a command=()
    build_nmap_base command "$family" "$target_file" "$prefix"
    command+=("$@")
    local command_rc=0
    if run_logged "$phase" "$name" "$COMMAND_TIMEOUT" -- "${command[@]}"; then
        command_rc=0
    else
        command_rc=$?
    fi
    (( DRY_RUN )) && return "$command_rc"
    if ! verify_nmap_runtime; then
        printf '%s\t%s\t%s\t%s\t%s\n' "$(timestamp)" "$phase" \
            "Nmap data verification after $name" 65 "scope/nmap-data.json" \
            >>"$RUN_DIR/logs/errors.tsv"
        append_event "$phase" "Nmap data verification after $name" \
            INVALID_OUTPUT 65 0 "scope/nmap-data.json"
        archive_evidence_files "${phase}-${name}-unstable-data" \
            "${prefix}.xml" "${prefix}.nmap" "${prefix}.gnmap" || return 1
        return 65
    fi
    if (( command_rc != 0 )); then
        archive_evidence_files "${phase}-${name}-partial" \
            "${prefix}.xml" "${prefix}.nmap" "${prefix}.gnmap" || return 1
        return "$command_rc"
    fi
    if ! validate_nmap_xml "${prefix}.xml"; then
        record_invalid_nmap_output "$phase" "$name" "${prefix}.xml"
        archive_evidence_files "${phase}-${name}-invalid" \
            "${prefix}.xml" "${prefix}.nmap" "${prefix}.gnmap" || return 1
        return 65
    fi
    ok "[$phase] Validated successful Nmap XML: ${prefix#"$RUN_DIR"/}.xml"
    return 0
}

phase_discovery() {
    local phase="discovery" failed=0
    local -a probes=()
    if (( EUID == 0 )); then
        probes=(-sn -PE -PP '-PS21-23,25,53,80,110,139,443,445,3389,5985,8080' \
            '-PA80,443,3389' '-PU53,123,161')
    else
        probes=(-sn)
        warn "Running unprivileged: Nmap discovery has reduced probe coverage"
    fi
    run_nmap_family "$phase" "IPv4 host discovery" 4 "$RUN_DIR/scope/targets.ipv4.txt" \
        "$RUN_DIR/raw/nmap-discovery-ipv4" "${probes[@]}" || failed=1
    run_nmap_family "$phase" "IPv6 host discovery" 6 "$RUN_DIR/scope/targets.ipv6.txt" \
        "$RUN_DIR/raw/nmap-discovery-ipv6" -sn || failed=1
    return "$failed"
}

extract_inventory() {
    python3 -I - "$RUN_DIR/raw" "$RUN_DIR/targets" "$RUN_DIR/scope/allowed.json" <<'PY'
import csv
import glob
import ipaddress
import json
import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

raw_dir, target_dir, scope_path = map(Path, sys.argv[1:])
target_dir.mkdir(parents=True, exist_ok=True)
scope = json.loads(scope_path.read_text())
allowed = [ipaddress.ip_network(item) for item in scope["ipv4_networks"] + scope["ipv6_networks"]]
hosts = {}
services = {}
discovery_up = set()

def in_scope(address):
    return any(address.version == network.version and address in network for network in allowed)

def clean(value):
    return (value or "").replace("\t", " ").replace("\r", " ").replace("\n", " ").strip()

for filename in sorted(glob.glob(str(raw_dir / "*.xml"))):
    try:
        root = ET.parse(filename).getroot()
    except (ET.ParseError, OSError):
        continue
    source = os.path.basename(filename)
    is_discovery = "nmap-discovery-" in source
    for host in root.findall("host"):
        address_node = next(
            (node for node in host.findall("address") if node.get("addrtype") in ("ipv4", "ipv6")),
            None,
        )
        if address_node is None:
            continue
        address = address_node.get("addr", "").split("%", 1)[0]
        try:
            parsed_address = ipaddress.ip_address(address)
        except ValueError:
            continue
        if not in_scope(parsed_address):
            continue
        status_node = host.find("status")
        status = status_node.get("state", "unknown") if status_node is not None else "unknown"
        hostname_nodes = host.findall("hostnames/hostname")
        hostname = clean(hostname_nodes[0].get("name", "")) if hostname_nodes else ""
        existing = hosts.get(address, {"hostname": "", "status": "unknown", "family": parsed_address.version})
        if hostname:
            existing["hostname"] = hostname
        if status == "up":
            existing["status"] = "up"
            if is_discovery:
                discovery_up.add(address)
        hosts[address] = existing

        for port_node in host.findall("ports/port"):
            protocol = port_node.get("protocol", "")
            try:
                port = int(port_node.get("portid", "0"))
            except ValueError:
                continue
            state_node = port_node.find("state")
            state = state_node.get("state", "unknown") if state_node is not None else "unknown"
            if not state.startswith("open"):
                continue
            service_node = port_node.find("service")
            record = {
                "address": address,
                "hostname": hostname,
                "protocol": protocol,
                "port": port,
                "state": state,
                "name": "unknown",
                "product": "",
                "version": "",
                "extra": "",
                "tunnel": "",
                "source": source,
            }
            if service_node is not None:
                for field in ("name", "product", "version", "extrainfo", "tunnel"):
                    destination = "extra" if field == "extrainfo" else field
                    record[destination] = clean(service_node.get(field, record.get(destination, "")))
            key = (address, protocol, port)
            score = sum(bool(record[field] and record[field] != "unknown") for field in ("name", "product", "version", "extra", "tunnel"))
            old = services.get(key)
            old_score = -1 if old is None else sum(bool(old[field] and old[field] != "unknown") for field in ("name", "product", "version", "extra", "tunnel"))
            if score >= old_score:
                services[key] = record

def address_key(value):
    parsed = ipaddress.ip_address(value)
    return (parsed.version, int(parsed))

with (target_dir / "hosts.tsv").open("w", newline="") as handle:
    writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
    writer.writerow(("address", "family", "hostname", "status"))
    for address in sorted(hosts, key=address_key):
        item = hosts[address]
        writer.writerow((address, item["family"], item["hostname"], item["status"]))

fields = ("address", "hostname", "protocol", "port", "state", "name", "product", "version", "extra", "tunnel", "source")
with (target_dir / "services.tsv").open("w", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t", lineterminator="\n")
    writer.writeheader()
    for key in sorted(services, key=lambda item: (address_key(item[0]), item[1], item[2])):
        writer.writerow(services[key])

open_addresses = {key[0] for key in services}
candidates = discovery_up | open_addresses
for version in (4, 6):
    selected = sorted((address for address in candidates if ipaddress.ip_address(address).version == version), key=address_key)
    (target_dir / f"candidates.ipv{version}.txt").write_text("".join(f"{address}\n" for address in selected))
    open_selected = sorted((address for address in open_addresses if ipaddress.ip_address(address).version == version), key=address_key)
    (target_dir / f"open-hosts.ipv{version}.txt").write_text("".join(f"{address}\n" for address in open_selected))

for protocol in ("tcp", "udp"):
    ports = sorted({key[2] for key in services if key[1] == protocol})
    (target_dir / f"open-{protocol}-ports.txt").write_text(",".join(map(str, ports)) + ("\n" if ports else ""))

print(f"Inventory: {len(hosts)} hosts, {len(services)} open/open-filtered services")
PY
}

phase_tcp() {
    local phase="tcp" failed=0 scan_type
    (( EUID == 0 )) && scan_type="-sS" || scan_type="-sT"

    run_nmap_family "$phase" "IPv4 top TCP ports" 4 "$RUN_DIR/scope/targets.ipv4.txt" \
        "$RUN_DIR/raw/nmap-tcp-quick-ipv4" -Pn "$scan_type" --top-ports 1000 --open -T4 || failed=1
    run_nmap_family "$phase" "IPv6 top TCP ports" 6 "$RUN_DIR/scope/targets.ipv6.txt" \
        "$RUN_DIR/raw/nmap-tcp-quick-ipv6" -Pn "$scan_type" --top-ports 1000 --open -T4 || failed=1
    if (( DRY_RUN )); then
        if [[ "$PROFILE" == "deep" ]]; then
            run_nmap_family "$phase" "IPv4 full TCP ports" 4 "$RUN_DIR/scope/targets.ipv4.txt" \
                "$RUN_DIR/raw/nmap-tcp-full-ipv4" -Pn "$scan_type" -p- --open -T4 || failed=1
            run_nmap_family "$phase" "IPv6 full TCP ports" 6 "$RUN_DIR/scope/targets.ipv6.txt" \
                "$RUN_DIR/raw/nmap-tcp-full-ipv6" -Pn "$scan_type" -p- --open -T4 || failed=1
        elif [[ "$PROFILE" == "standard" ]]; then
            record_skip "$phase" "full TCP preview" "standard-profile targets depend on quick-scan results"
        fi
        return "$failed"
    fi
    extract_inventory || return 1

    if [[ "$PROFILE" != "quick" ]]; then
        local targets4="$RUN_DIR/targets/candidates.ipv4.txt"
        local targets6="$RUN_DIR/targets/candidates.ipv6.txt"
        if [[ "$PROFILE" == "deep" ]]; then
            targets4="$RUN_DIR/scope/targets.ipv4.txt"
            targets6="$RUN_DIR/scope/targets.ipv6.txt"
        fi
        run_nmap_family "$phase" "IPv4 full TCP ports" 4 "$targets4" \
            "$RUN_DIR/raw/nmap-tcp-full-ipv4" -Pn "$scan_type" -p- --open -T4 || failed=1
        run_nmap_family "$phase" "IPv6 full TCP ports" 6 "$targets6" \
            "$RUN_DIR/raw/nmap-tcp-full-ipv6" -Pn "$scan_type" -p- --open -T4 || failed=1
        extract_inventory || return 1
    fi
    return "$failed"
}

phase_udp() {
    local phase="udp" count=100 failed=0
    if (( EUID != 0 )); then
        if (( DRY_RUN )); then
            warn "[$phase] previewing UDP commands; execution will require root privileges"
        else
            record_skip "$phase" "UDP scan" "root privileges are required"
            return 1
        fi
    fi
    case "$PROFILE" in
        quick) count=20 ;;
        standard) count=100 ;;
        deep) count=250 ;;
    esac
    # 2222/udp is EtherNet/IP cyclic I/O and sits at frequency rank 33, so it
    # was inside every --top-ports value this script uses.  Exclude the OT UDP
    # set before nmap selects its top-ports list.
    local ot_exclude
    ot_exclude="$(ot_udp_exclude_spec)"
    run_nmap_family "$phase" "IPv4 top $count UDP ports" 4 "$RUN_DIR/scope/targets.ipv4.txt" \
        "$RUN_DIR/raw/nmap-udp-ipv4" -Pn -sU -sV --version-light --top-ports "$count" \
        --exclude-ports "$ot_exclude" --open -T4 || failed=1
    run_nmap_family "$phase" "IPv6 top $count UDP ports" 6 "$RUN_DIR/scope/targets.ipv6.txt" \
        "$RUN_DIR/raw/nmap-udp-ipv6" -Pn -sU -sV --version-light --top-ports "$count" \
        --exclude-ports "$ot_exclude" --open -T4 || failed=1
    if (( DRY_RUN == 0 )) && ! extract_inventory; then
        failed=1
    fi
    return "$failed"
}

# Builds the nmap --exclude-ports value that keeps UDP probing off OT ports.
ot_udp_exclude_spec() {
    local joined
    joined="$(IFS=,; printf '%s' "${OT_UDP_PORTS[*]:-}")"
    printf '%s,%s' "$joined" "$OT_UDP_PORT_RANGES"
}

# Splits a comma-separated nmap port list into the ports we may probe and the
# OT ports we may not.  Sets OT_PORTS_KEPT and OT_PORTS_WITHHELD rather than
# echoing, because a command substitution would run this in a subshell and
# discard the withheld list, leaving the operator with no notice that OT
# endpoints were found and skipped.
OT_PORTS_KEPT=""
OT_PORTS_LIGHT=""
OT_PORTS_WITHHELD=""
# Expands a port spec that may contain ranges into the caller-named array.
expand_port_spec() {
    local spec="$1" name="$2" item low high value
    local -n out="$name"
    out=()
    local saved_ifs="$IFS"
    IFS=,
    for item in $spec; do
        [[ -n "$item" ]] || continue
        if [[ "$item" == *-* ]]; then
            low="${item%%-*}"; high="${item##*-}"
            for (( value = low; value <= high; value++ )); do out+=("$value"); done
        else
            out+=("$item")
        fi
    done
    IFS="$saved_ifs"
}
filter_ot_ports() {
    local list="$1" port
    local -a keep=() light=() withheld=() light_ports=()
    local -A is_ot=() is_light=()
    for port in "${OT_TCP_PORTS[@]}"; do is_ot["$port"]=1; done
    expand_port_spec "$OT_TCP_LIGHT_RANGES" light_ports
    for port in "${light_ports[@]}"; do is_light["$port"]=1; done
    local saved_ifs="$IFS"
    IFS=,
    for port in $list; do
        [[ -n "$port" ]] || continue
        if [[ -n "${is_ot[$port]:-}" ]]; then
            withheld+=("$port")
        elif [[ -n "${is_light[$port]:-}" ]]; then
            light+=("$port")
        else
            keep+=("$port")
        fi
    done
    IFS="$saved_ifs"
    OT_PORTS_KEPT="$(IFS=,; printf '%s' "${keep[*]:-}")"
    OT_PORTS_LIGHT="$(IFS=,; printf '%s' "${light[*]:-}")"
    OT_PORTS_WITHHELD="$(IFS=,; printf '%s' "${withheld[*]:-}")"
}

# Records every discovered OT endpoint to a quarantine file.  These are
# reported but deliberately never probed; see the OT_TCP_PORTS comment.
record_ot_quarantine() {
    local services="$RUN_DIR/targets/services.tsv"
    local destination="$RUN_DIR/targets/ot-quarantine.tsv"
    [[ -s "$services" ]] || { : >"$destination"; return 0; }
    python3 -I - "$services" "$destination" \
        "$(IFS=,; printf '%s' "${OT_TCP_PORTS[*]:-}")" \
        "$(ot_udp_exclude_spec)" <<'PY'
import csv
import sys
from pathlib import Path

services, destination, tcp_spec, udp_spec = (
    Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3], sys.argv[4])


def expand(spec):
    ports = set()
    for item in spec.split(","):
        item = item.strip()
        if not item:
            continue
        if "-" in item:
            low, _, high = item.partition("-")
            ports.update(range(int(low), int(high) + 1))
        else:
            ports.add(int(item))
    return ports


watched = {"tcp": expand(tcp_spec), "udp": expand(udp_spec)}
rows = []
with services.open(newline="") as handle:
    for row in csv.DictReader(handle, delimiter="\t"):
        try:
            port = int(row["port"])
        except (KeyError, TypeError, ValueError):
            continue
        protocol = (row.get("protocol") or "").lower()
        if port in watched.get(protocol, ()):
            rows.append(row)

fields = ("address", "hostname", "protocol", "port", "name", "product", "version", "extra")
with destination.open("w", newline="") as handle:
    writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
    writer.writerow(fields)
    for row in sorted(rows, key=lambda item: (item["address"], item["protocol"], int(item["port"]))):
        writer.writerow([row.get(field, "") for field in fields])
print(len(rows))
PY
}

phase_services() {
    local phase="services" failed=0 ports scan_type
    (( DRY_RUN )) && { record_skip "$phase" "service scan" "dry-run has no discovered ports"; return 0; }
    extract_inventory || return 1
    ports="$(<"$RUN_DIR/targets/open-tcp-ports.txt")"
    [[ -n "$ports" ]] || { record_skip "$phase" "TCP service scan" "no open TCP ports were discovered"; return 0; }
    # Identify OT endpoints, then take them out of the version/NSE port list.
    record_ot_quarantine >/dev/null || return 1
    filter_ot_ports "$ports"
    ports="$OT_PORTS_KEPT"
    if [[ -n "$OT_PORTS_WITHHELD" ]]; then
        warn "[$phase] OT/ICS ports discovered and withheld from service probing: $OT_PORTS_WITHHELD"
        warn "[$phase] these are recorded in targets/ot-quarantine.tsv for manual review"
        record_skip "$phase" "OT/ICS service probing" \
            "ports $OT_PORTS_WITHHELD are industrial control endpoints; version and NSE probing is withheld by policy"
    fi
    (( EUID == 0 )) && scan_type="-sS" || scan_type="-sT"

    # Ambiguous serial device-server ports: identify with a zero-payload probe
    # and no NSE, instead of either skipping them or walking the probe database.
    if [[ -n "$OT_PORTS_LIGHT" ]]; then
        warn "[$phase] serial device-server ports probed at zero intensity only: $OT_PORTS_LIGHT"
        local -a light=(-Pn "$scan_type" -sV --version-intensity 0 -p "$OT_PORTS_LIGHT" -T3)
        run_nmap_family "$phase" "IPv4 serial device-server identification" 4 \
            "$RUN_DIR/targets/open-hosts.ipv4.txt" "$RUN_DIR/raw/nmap-serial-ipv4" "${light[@]}" || failed=1
        run_nmap_family "$phase" "IPv6 serial device-server identification" 6 \
            "$RUN_DIR/targets/open-hosts.ipv6.txt" "$RUN_DIR/raw/nmap-serial-ipv6" "${light[@]}" || failed=1
    fi

    if [[ -z "$ports" ]]; then
        record_skip "$phase" "TCP service scan" \
            "no discovered TCP port is eligible for full service probing"
        extract_inventory || return 1
        return "$failed"
    fi

    [[ -n "$NMAP_SERVICE_NSE_SCRIPTS" ]] \
        || { error "[$phase] Absolute service NSE binding is unavailable"; return 1; }
    local -a extra=(-Pn "$scan_type" -sV --version-all -p "$ports" \
        --script "$NMAP_SERVICE_NSE_SCRIPTS" --script-timeout 2m -T4)
    (( EUID == 0 )) && extra+=(-O --osscan-limit)

    run_nmap_family "$phase" "IPv4 service and bounded NSE enumeration" 4 \
        "$RUN_DIR/targets/open-hosts.ipv4.txt" "$RUN_DIR/raw/nmap-services-ipv4" "${extra[@]}" || failed=1
    run_nmap_family "$phase" "IPv6 service and bounded NSE enumeration" 6 \
        "$RUN_DIR/targets/open-hosts.ipv6.txt" "$RUN_DIR/raw/nmap-services-ipv6" "${extra[@]}" || failed=1
    extract_inventory || return 1
    return "$failed"
}

build_followup_targets() {
    python3 -I - "$RUN_DIR/targets/services.tsv" "$RUN_DIR/scope/allowed.json" \
        "$RUN_DIR/scope/resolution.tsv" "$RUN_DIR/targets" <<'PY'
import csv
import ipaddress
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

services_path, scope_path, resolution_path, output_path = map(Path, sys.argv[1:])
scope = json.loads(scope_path.read_text())
allowed = [ipaddress.ip_network(item) for item in scope["ipv4_networks"] + scope["ipv6_networks"]]
output = defaultdict(set)
aliases = defaultdict(set)

def in_scope(address):
    parsed = ipaddress.ip_address(address)
    return any(parsed in network for network in allowed)

def endpoint(address, port):
    return f"[{address}]:{port}" if ":" in address else f"{address}:{port}"

WEB_PORTS = {
    80, 443, 591, 3000, 4200, 5000, 5601, 7001, 8000, 8001, 8008, 8080, 8081,
    8088, 8090, 8180, 8181, 8443, 8880, 8888, 9000, 9080, 9090, 9200, 9443,
    10000,
}
WEB_PRODUCT_RE = re.compile(
    r"nginx|apache|httpd|\biis\b|tomcat|jetty|lighttpd|caddy|uvicorn|gunicorn"
    r"|werkzeug|kestrel|node\.js|express|jboss|wildfly|weblogic|websphere"
    r"|gitea|gitlab|grafana|jenkins|phpmyadmin|kibana|elasticsearch|webmin"
)
# TLS fronting one of these is not a web service; probing it as HTTP is noise.
NON_HTTP_TLS_RE = re.compile(
    r"^(smtp|imap|pop3|ldap|ftp|ssh|domain|sieve|xmpp|irc|nntp|telnet|rdp|vnc|mysql|postgresql|mongod)"
)

def sort_key(line):
    # Address-ordered, not text-ordered: a text sort puts 10.0.0.10 before
    # 10.0.0.2, and for http.txt it puts every http:// URL before every
    # https:// one, so a --max-followups cap would drop all TLS targets first.
    value = line
    if "://" in value:
        value = value.split("://", 1)[1]
    if value.startswith("["):
        host, _, remainder = value[1:].partition("]:")
        port_text = remainder.split("\t", 1)[0]
    else:
        fields = value.replace("\t", ":").split(":")
        host = fields[0]
        port_text = fields[1] if len(fields) > 1 else ""
    try:
        parsed = ipaddress.ip_address(host)
    except ValueError:
        return (9, 0, 0, line)
    port = int(port_text) if port_text.isdigit() else 0
    return (parsed.version, int(parsed), port, line)

if resolution_path.exists():
    with resolution_path.open(newline="") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            if row.get("kind") != "hostname" or row.get("disposition") != "target":
                continue
            hostname = row.get("source", "").rstrip(".").lower()
            resolved = row.get("resolved", "").split("%", 1)[0]
            if not re.fullmatch(r"[a-z0-9.-]{1,253}", hostname):
                continue
            try:
                parsed = ipaddress.ip_address(resolved)
            except ValueError:
                continue
            if in_scope(str(parsed)):
                aliases[str(parsed)].add(hostname)

if services_path.exists():
    with services_path.open(newline="") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            address = row["address"]
            if not in_scope(address):
                continue
            port = int(row["port"])
            protocol = row["protocol"]
            service = row["name"].lower()
            tunnel = row["tunnel"].lower()
            row_text = f"{address}\t{port}"
            product_text = f"{row['product']} {row['extra']}".lower()
            # -sV often fails to fingerprint Go/Node/Java app servers, leaving the
            # nmap-services port name (3000 -> "ppp", 9200 -> "wap-wsp"), so port
            # number, TLS tunnel, and product text all have to be able to elect a
            # web target.  TLS on a known non-HTTP protocol must not be probed.
            looks_web = (
                "http" in service
                or port in WEB_PORTS
                or WEB_PRODUCT_RE.search(product_text) is not None
                or (tunnel == "ssl" and not NON_HTTP_TLS_RE.match(service))
            )
            if protocol == "tcp" and looks_web:
                secure = tunnel == "ssl" or "https" in service or port in {443, 8443, 9443}
                scheme = "https" if secure else "http"
                output["http.txt"].add(f"{scheme}://{endpoint(address, port)}")
                for hostname in aliases[address]:
                    output["http-vhosts.tsv"].add(f"{address}\t{port}\t{scheme}\t{hostname}")
            if protocol == "tcp" and (service in {"microsoft-ds", "netbios-ssn"} or port in {139, 445}):
                output["smb.tsv"].add(row_text)
            if protocol == "tcp" and ("ldap" in service or port in {389, 636, 3268, 3269}):
                scheme = "ldaps" if tunnel == "ssl" or port in {636, 3269} else "ldap"
                output["ldap.tsv"].add(f"{address}\t{port}\t{scheme}")
            if port == 53 and protocol in {"tcp", "udp"}:
                output["dns.tsv"].add(f"{address}\t{port}\t{protocol}")
            if protocol == "udp" and ("snmp" in service or port == 161):
                output["snmp.tsv"].add(row_text)
            if service in {"rpcbind", "nfs", "mountd"} or port in {111, 2049}:
                output["nfs.tsv"].add(f"{address}\t{port}\t{protocol}")
            if protocol == "tcp" and (service == "ssh" or port == 22):
                output["ssh.tsv"].add(row_text)
            if protocol == "tcp" and (service.startswith("smtp") or port in {25, 465, 587}):
                output["smtp.tsv"].add(row_text)
            if protocol == "tcp" and (tunnel == "ssl" or service in {"https", "ssl"} or port in {443, 465, 636, 993, 995, 8443, 9443}):
                output["tls.tsv"].add(row_text)

names = ("http.txt", "http-vhosts.tsv", "smb.tsv", "ldap.tsv", "dns.tsv", "snmp.tsv", "nfs.tsv", "ssh.tsv", "smtp.tsv", "tls.tsv")
for name in names:
    (output_path / name).write_text(
        "".join(f"{line}\n" for line in sorted(output[name], key=sort_key))
    )
print("Follow-up targets: " + ", ".join(f"{name}={len(output[name])}" for name in names))
PY
    # Empty target sets must not leave a capped subset from an earlier phase.
    if [[ ! -s "$RUN_DIR/targets/http.txt" ]]; then
        : >"$RUN_DIR/targets/http.capped.txt" || return 1
    fi
    if [[ ! -s "$RUN_DIR/targets/http-vhosts.tsv" ]]; then
        : >"$RUN_DIR/targets/http-vhosts.capped.tsv" || return 1
    fi
}

limit_notice() {
    local phase="$1" file="$2" label="$3" count
    [[ -f "$file" ]] || return 0
    count="$(wc -l <"$file")"
    if (( count > MAX_FOLLOWUPS )); then
        warn "[$phase] $label has $count targets; limiting follow-ups to $MAX_FOLLOWUPS"
    fi
}

cap_followup_file() {
    local source="$1" destination="$2"
    if ! head -n "$MAX_FOLLOWUPS" -- "$source" >"$destination"; then
        error "Could not write capped follow-up target file: ${destination#"$RUN_DIR"/}"
        return 1
    fi
}

write_owned_text_file() {
    local destination="$1" content="$2"
    local temporary
    temporary="$RUN_DIR/.state/$(safe_slug "${destination##*/}").tmp.$$.$RANDOM"
    if ! printf '%s' "$content" >"$temporary"; then
        rm -f -- "$temporary"
        return 1
    fi
    chmod 600 -- "$temporary" || { rm -f -- "$temporary"; return 1; }
    mv -f -- "$temporary" "$destination"
}

find_pd_httpx() {
    if have httpx-toolkit; then
        command -v httpx-toolkit
        return 0
    fi
    if have httpx && httpx -version 2>&1 | grep -qi projectdiscovery; then
        command -v httpx
        return 0
    fi
    return 1
}

find_nuclei_templates() {
    local candidate first_template invoking_home=""
    local -a candidates=()
    if (( EUID == 0 )) && [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
        invoking_home="$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6 || true)"
        if [[ -n "$invoking_home" ]]; then
            candidates+=("$invoking_home/nuclei-templates" "$invoking_home/.local/share/nuclei-templates")
        fi
    fi
    candidates+=("$HOME/nuclei-templates" "${XDG_DATA_HOME:-$HOME/.local/share}/nuclei-templates" /usr/share/nuclei-templates)
    for candidate in "${candidates[@]}"; do
        [[ -d "$candidate" ]] || continue
        first_template="$(find "$candidate" -type f \( -name '*.yaml' -o -name '*.yml' \) -print -quit 2>/dev/null)"
        if [[ -n "$first_template" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

followup_web() {
    local phase="followups" file="$RUN_DIR/targets/http.txt" capped_file="$RUN_DIR/targets/http.capped.txt"
    local vhost_file="$RUN_DIR/targets/http-vhosts.tsv" vhost_capped="$RUN_DIR/targets/http-vhosts.capped.tsv"
    local httpx_bin="" url index=0 host port scheme hostname endpoint pinned_url virtual_url resolve_entry host_header
    local httpx_config="$RUN_DIR/scope/httpx-config.yaml"
    local nikto_config="$RUN_DIR/scope/nikto.conf"
    [[ -s "$file" ]] || { record_skip "$phase" "web enumeration" "no HTTP services"; return 0; }
    limit_notice "$phase" "$file" "web"
    cap_followup_file "$file" "$capped_file" || return 1
    write_owned_text_file "$httpx_config" $'{}\n' || return 1
    if httpx_bin="$(find_pd_httpx)"; then
        local httpx_output="$RUN_DIR/raw/httpx.jsonl"
        local httpx_temporary="${httpx_output}.partial.$$.$RANDOM" httpx_rc=0
        if run_logged "$phase" "ProjectDiscovery HTTP inventory" "30m" -- env \
                -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
                NO_PROXY='*' no_proxy='*' "$httpx_bin" -config "$httpx_config" \
                -l "$capped_file" -verbose -json -status-code -title -tech-detect -web-server -ip -cname \
                -timeout 10 -retries 1 -rate-limit 50 -no-stdin -disable-update-check -o "$httpx_temporary"; then
            httpx_rc=0
        else
            httpx_rc=$?
        fi
        finish_optional_output "$phase" "ProjectDiscovery HTTP inventory" jsonl \
            "$httpx_temporary" "$httpx_output" "$httpx_rc" || return 1
    elif have curl; then
        while IFS= read -r url && (( index < MAX_FOLLOWUPS )); do
            index=$((index + 1))
            run_optional "$phase" "HTTP headers $url" "45s" -- env \
                -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
                NO_PROXY='*' no_proxy='*' curl -q -ksS -I --noproxy '*' --max-time 20 \
                --user-agent "CPTC-Enumerator/$SCRIPT_VERSION" "$url"
        done <"$capped_file"
    else
        record_skip "$phase" "HTTP probe" "neither ProjectDiscovery httpx nor curl is installed"
    fi

    if have whatweb; then
        local whatweb_output="$RUN_DIR/raw/whatweb.json"
        local whatweb_temporary="${whatweb_output}.partial.$$.$RANDOM" whatweb_rc=0
        if run_logged "$phase" "WhatWeb technology inventory" "30m" -- env \
                -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
                NO_PROXY='*' no_proxy='*' whatweb -v --color=never --follow-redirect=never \
                -i "$capped_file" --log-json="$whatweb_temporary"; then
            whatweb_rc=0
        else
            whatweb_rc=$?
        fi
        finish_optional_output "$phase" "WhatWeb technology inventory" json \
            "$whatweb_temporary" "$whatweb_output" "$whatweb_rc" || return 1
    fi

    if [[ -s "$vhost_file" ]]; then
        limit_notice "$phase" "$vhost_file" "frozen hostname aliases"
        cap_followup_file "$vhost_file" "$vhost_capped" || return 1
        index=0
        while IFS=$'\t' read -r host port scheme hostname; do
            index=$((index + 1))
            [[ "$host" == *:* ]] && endpoint="[$host]:$port" || endpoint="$host:$port"
            pinned_url="$scheme://$endpoint/"
            virtual_url="$scheme://$hostname:$port/"
            host_header="$hostname"
            if [[ ( "$scheme" == http && "$port" != 80 ) || ( "$scheme" == https && "$port" != 443 ) ]]; then
                host_header="$hostname:$port"
            fi
            if [[ "$host" == *:* ]]; then
                resolve_entry="$hostname:$port:[$host]"
            else
                resolve_entry="$hostname:$port:$host"
            fi
            if [[ -n "$httpx_bin" ]]; then
                local vhost_output
                vhost_output="$RUN_DIR/raw/httpx-vhost-$(printf '%04d' "$index").jsonl"
                local vhost_temporary="${vhost_output}.partial.$$.$RANDOM" vhost_rc=0
                if run_logged "$phase" "HTTP virtual host $hostname via $host:$port" "3m" -- env \
                        -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
                        NO_PROXY='*' no_proxy='*' "$httpx_bin" -config "$httpx_config" \
                        -u "$pinned_url" -H "Host: $host_header" -sni-name "$hostname" -verbose -json \
                        -status-code -title -tech-detect -web-server -timeout 10 -retries 1 -rate-limit 10 \
                        -no-stdin -disable-update-check -o "$vhost_temporary"; then
                    vhost_rc=0
                else
                    vhost_rc=$?
                fi
                finish_optional_output "$phase" "HTTP virtual host $hostname via $host:$port" jsonl \
                    "$vhost_temporary" "$vhost_output" "$vhost_rc" || return 1
            elif have curl; then
                run_optional "$phase" "HTTP virtual host $hostname via $host:$port" "45s" -- env \
                    -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
                    NO_PROXY='*' no_proxy='*' curl -q -ksS -I --noproxy '*' --max-time 20 \
                    --resolve "$resolve_entry" --user-agent "CPTC-Enumerator/$SCRIPT_VERSION" "$virtual_url"
            fi
        done <"$vhost_capped"
    fi

    if (( ACTIVE_WEB )); then
        index=0
        if have nikto; then
            write_owned_text_file "$nikto_config" \
                $'# CPTC runner-owned empty Nikto configuration\n' || return 1
            while IFS= read -r url && (( index < MAX_FOLLOWUPS && index < 64 )); do
                index=$((index + 1))
                run_optional "$phase" "Nikto $url" "15m" -- env \
                    -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
                    NO_PROXY='*' no_proxy='*' nikto -config "$nikto_config" -ask no \
                    -nointeractive -nocheck -Tuning 123bde -h "$url"
            done <"$capped_file"
        fi

        local gobuster_bin="" wordlist="" wordlist_candidate=""
        have gobuster && gobuster_bin="$(command -v gobuster)"
        for wordlist_candidate in \
            /usr/share/seclists/Discovery/Web-Content/raft-small-words.txt \
            /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt \
            /usr/share/wordlists/dirb/common.txt; do
            if [[ -f "$wordlist_candidate" && -r "$wordlist_candidate" ]]; then
                wordlist="$wordlist_candidate"
                break
            fi
        done
        if [[ -n "$gobuster_bin" && -n "$wordlist" ]]; then
            freeze_active_web_wordlist "$wordlist" >/dev/null || return 1
            wordlist="$RUN_DIR/scope/gobuster-wordlist.txt"
            info "[$phase] Frozen active-web wordlist and provenance under scope/"
            index=0
            while IFS= read -r url && (( index < MAX_FOLLOWUPS && index < 32 )); do
                index=$((index + 1))
                if ! verify_active_web_wordlist; then
                    record_active_web_wordlist_drift "$url" before
                    return 1
                fi
                run_optional "$phase" "Gobuster content discovery $url" "12m" -- env \
                    -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
                    NO_PROXY='*' no_proxy='*' "$gobuster_bin" dir --url "$url" --wordlist "$wordlist" \
                    --threads 10 --delay 200ms --timeout 10s --no-tls-validation \
                    --follow-redirect=false --no-color --verbose
                if ! verify_active_web_wordlist; then
                    record_active_web_wordlist_drift "$url" after
                    return 1
                fi
            done <"$capped_file"
        elif [[ -n "$gobuster_bin" ]]; then
            record_skip "$phase" "Gobuster content discovery" "no supported wordlist is installed"
        fi
    fi
}

followup_smb() {
    local phase="followups" file="$RUN_DIR/targets/smb.tsv" host port index=0
    [[ -s "$file" ]] || { record_skip "$phase" "SMB enumeration" "no SMB services"; return 0; }
    limit_notice "$phase" "$file" "SMB"
    while IFS=$'\t' read -r host port && (( index < MAX_FOLLOWUPS )); do
        index=$((index + 1))
        if have smbclient; then
            run_optional "$phase" "SMB anonymous shares $host:$port" "3m" -- smbclient -L "//$host" \
                -p "$port" -N -g --option='client min protocol=SMB2'
        fi
        if have rpcclient && [[ "$port" == 445 || "$port" == 139 ]]; then
            run_optional "$phase" "RPC null-session metadata $host" "3m" -- rpcclient -N -U '' -p "$port" "$host" \
                -c 'srvinfo;enumdomains;querydominfo;getdompwinfo;netshareenumall'
        fi
        if have enum4linux-ng && [[ "$port" == 445 || "$port" == 139 ]]; then
            run_optional "$phase" "enum4linux-ng $host" "10m" -- enum4linux-ng -A "$host"
        fi
        local nxc_bin=""
        if have nxc; then nxc_bin="$(command -v nxc)"; elif have netexec; then nxc_bin="$(command -v netexec)"; fi
        if [[ -n "$nxc_bin" && ( "$port" == 445 || "$port" == 139 ) ]]; then
            run_optional "$phase" "NetExec anonymous SMB $host" "5m" -- "$nxc_bin" smb "$host" \
                --port "$port" -u '' -p '' --shares --users --groups --pass-pol
        fi
    done <"$file"
}

followup_ldap() {
    local phase="followups" file="$RUN_DIR/targets/ldap.tsv" host port scheme uri index=0
    [[ -s "$file" ]] || { record_skip "$phase" "LDAP enumeration" "no LDAP services"; return 0; }
    have ldapsearch || { record_skip "$phase" "LDAP enumeration" "ldapsearch is not installed"; return 0; }
    while IFS=$'\t' read -r host port scheme && (( index < MAX_FOLLOWUPS )); do
        index=$((index + 1))
        if [[ "$host" == *:* ]]; then uri="$scheme://[$host]:$port"; else uri="$scheme://$host:$port"; fi
        run_optional "$phase" "LDAP RootDSE $host:$port" "2m" -- env LDAPTLS_REQCERT=never ldapsearch \
            -LLL -x -H "$uri" -o nettimeout=10 -s base -b '' namingContexts defaultNamingContext \
            rootDomainNamingContext dnsHostName supportedLDAPVersion supportedSASLMechanisms
    done <"$file"
}

followup_dns() {
    local phase="followups" file="$RUN_DIR/targets/dns.tsv" host port protocol index=0 record
    [[ -s "$file" ]] || { record_skip "$phase" "DNS enumeration" "no DNS services"; return 0; }
    have dig || { record_skip "$phase" "DNS enumeration" "dig is not installed"; return 0; }
    while IFS=$'\t' read -r host port protocol && (( index < MAX_FOLLOWUPS )); do
        index=$((index + 1))
        local -a transport=()
        [[ "$protocol" == tcp ]] && transport=(+tcp)
        run_optional "$phase" "DNS version query $host:$port/$protocol" "45s" -- dig -r "@$host" -p "$port" \
            +time=3 +tries=1 "${transport[@]}" version.bind chaos txt
        if [[ -n "$DOMAIN" ]]; then
            for record in SOA NS MX TXT _ldap._tcp.dc._msdcs _kerberos._tcp _gc._tcp; do
                if [[ "$record" == _* ]]; then
                    run_optional "$phase" "DNS SRV $record.$DOMAIN via $host" "45s" -- dig -r "@$host" -p "$port" \
                        +time=3 +tries=1 "${transport[@]}" "$record.$DOMAIN" SRV
                else
                    run_optional "$phase" "DNS $record $DOMAIN via $host" "45s" -- dig -r "@$host" -p "$port" \
                        +time=3 +tries=1 "${transport[@]}" "$DOMAIN" "$record"
                fi
            done
            run_optional "$phase" "DNS AXFR $DOMAIN via $host" "2m" -- dig -r "@$host" -p "$port" \
                +time=5 +tries=1 "${transport[@]}" "$DOMAIN" AXFR
        fi
    done <"$file"
}

load_snmp_communities() {
    declare -ga SNMP_COMMUNITIES=(public)
    [[ -n "$SNMP_COMMUNITY_FILE" ]] || return 0
    SNMP_COMMUNITIES=()
    local value
    # '|| [[ -n $value ]]' keeps a final line that has no newline; '#' is only a
    # comment at the start of a line, since it is legal inside a community string.
    while IFS= read -r value || [[ -n "$value" ]]; do
        value="${value%$'\r'}"
        [[ "$value" == \#* ]] && continue
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        [[ -n "$value" ]] || continue
        SNMP_COMMUNITIES+=("$value")
        SECRET_VALUES+=("$value")
    done <"$SNMP_COMMUNITY_FILE"
    ((${#SNMP_COMMUNITIES[@]})) || die "SNMP community file contains no usable entries"
}

followup_snmp() {
    local phase="followups" file="$RUN_DIR/targets/snmp.tsv" host port community transport index=0
    [[ -s "$file" ]] || { record_skip "$phase" "SNMP enumeration" "no SNMP services"; return 0; }
    have snmpwalk || { record_skip "$phase" "SNMP enumeration" "snmpwalk is not installed"; return 0; }
    load_snmp_communities
    while IFS=$'\t' read -r host port && (( index < MAX_FOLLOWUPS )); do
        index=$((index + 1))
        if [[ "$host" == *:* ]]; then transport="udp6:[$host]:$port"; else transport="udp:$host:$port"; fi
        for community in "${SNMP_COMMUNITIES[@]}"; do
            run_optional "$phase" "SNMP system tree $host:$port" "3m" -- snmpwalk -v2c -c "$community" \
                -t 2 -r 1 "$transport" 1.3.6.1.2.1.1
        done
    done <"$file"
}

followup_nfs() {
    local phase="followups" file="$RUN_DIR/targets/nfs.tsv" host port protocol index=0
    [[ -s "$file" ]] || { record_skip "$phase" "NFS/RPC enumeration" "no NFS/RPC services"; return 0; }
    while IFS=$'\t' read -r host port protocol && (( index < MAX_FOLLOWUPS )); do
        index=$((index + 1))
        if have rpcinfo; then
            run_optional "$phase" "RPC program list $host" "2m" -- rpcinfo -p "$host"
        fi
        if have showmount; then
            run_optional "$phase" "NFS exports $host" "2m" -- showmount -e "$host"
        fi
    done <"$file"
}

followup_ssh() {
    local phase="followups" file="$RUN_DIR/targets/ssh.tsv" host port index=0
    [[ -s "$file" ]] || { record_skip "$phase" "SSH enumeration" "no SSH services"; return 0; }
    while IFS=$'\t' read -r host port && (( index < MAX_FOLLOWUPS )); do
        index=$((index + 1))
        if have ssh-keyscan; then
            run_optional "$phase" "SSH host keys $host:$port" "45s" -- ssh-keyscan -T 8 -p "$port" "$host"
        fi
        if have ssh-audit; then
            run_optional "$phase" "SSH algorithm audit $host:$port" "3m" -- ssh-audit -p "$port" "$host"
        fi
    done <"$file"
}

followup_smtp() {
    local phase="followups" file="$RUN_DIR/targets/smtp.tsv" host port index=0
    [[ -s "$file" ]] || { record_skip "$phase" "SMTP enumeration" "no SMTP services"; return 0; }
    have swaks || { record_skip "$phase" "SMTP enumeration" "swaks is not installed"; return 0; }
    while IFS=$'\t' read -r host port && (( index < MAX_FOLLOWUPS )); do
        index=$((index + 1))
        run_optional "$phase" "SMTP EHLO $host:$port" "1m" -- swaks --server "$host" --port "$port" \
            --quit-after EHLO --timeout 10s
    done <"$file"
}

followup_tls() {
    local phase="followups" file="$RUN_DIR/targets/tls.tsv" host port endpoint index=0
    [[ -s "$file" ]] || { record_skip "$phase" "TLS enumeration" "no TLS services"; return 0; }
    have sslscan || { record_skip "$phase" "TLS enumeration" "sslscan is not installed"; return 0; }
    while IFS=$'\t' read -r host port && (( index < MAX_FOLLOWUPS )); do
        index=$((index + 1))
        [[ "$host" == *:* ]] && endpoint="[$host]:$port" || endpoint="$host:$port"
        run_optional "$phase" "TLS configuration $host:$port" "5m" -- sslscan --no-colour "$endpoint"
    done <"$file"
}

phase_followups() {
    (( DRY_RUN )) && { record_skip "followups" "protocol follow-ups" "dry-run has no service inventory"; return 0; }
    archive_evidence_files "followups-web-prior" \
        "$RUN_DIR/raw/httpx.jsonl" "$RUN_DIR/raw/httpx-vhost-"*.jsonl \
        "$RUN_DIR/raw/whatweb.json" "$RUN_DIR/scope/httpx-config.yaml" \
        "$RUN_DIR/scope/nikto.conf" "$RUN_DIR/scope/gobuster-wordlist.txt" \
        "$RUN_DIR/scope/gobuster-wordlist.json" || return 1
    extract_inventory || return 1
    build_followup_targets || return 1
    followup_web || return 1
    followup_smb || return 1
    followup_ldap || return 1
    followup_dns || return 1
    followup_snmp || return 1
    followup_nfs || return 1
    followup_ssh || return 1
    followup_smtp || return 1
    if [[ "$PROFILE" != quick ]]; then
        followup_tls || return 1
    fi
}

phase_vuln() {
    local phase="vuln" ports httpx_input="$RUN_DIR/targets/http.txt" nuclei_templates=""
    local vhost_file="$RUN_DIR/targets/http-vhosts.tsv" vhost_capped="$RUN_DIR/targets/http-vhosts.capped.tsv"
    local host port scheme hostname endpoint pinned_url host_header index=0
    local nuclei_config="$RUN_DIR/scope/nuclei-config.yaml"
    (( VULN_ENABLED )) || { record_skip "$phase" "vulnerability checks" "not explicitly enabled"; return 0; }
    (( DRY_RUN )) && { record_skip "$phase" "vulnerability checks" "dry-run has no inventory"; return 0; }
    archive_evidence_files "vuln-prior" \
        "$RUN_DIR/raw/nmap-vuln-ipv4.xml" "$RUN_DIR/raw/nmap-vuln-ipv4.nmap" \
        "$RUN_DIR/raw/nmap-vuln-ipv4.gnmap" "$RUN_DIR/raw/nmap-vuln-ipv6.xml" \
        "$RUN_DIR/raw/nmap-vuln-ipv6.nmap" "$RUN_DIR/raw/nmap-vuln-ipv6.gnmap" \
        "$RUN_DIR/raw/nuclei.jsonl" "$RUN_DIR/raw/nuclei-vhost-"*.jsonl \
        "$RUN_DIR/scope/nuclei-config.yaml" "$RUN_DIR/scope/nuclei-template-tree.json" || return 1
    extract_inventory || return 1
    build_followup_targets || return 1
    if [[ -s "$httpx_input" ]]; then
        cap_followup_file "$httpx_input" "$RUN_DIR/targets/http.capped.txt" || return 1
        httpx_input="$RUN_DIR/targets/http.capped.txt"
    fi
    ports="$(<"$RUN_DIR/targets/open-tcp-ports.txt")"
    # OT endpoints are excluded here for the same reason as in phase_services.
    filter_ot_ports "$ports"
    ports="$OT_PORTS_KEPT"
    if [[ -n "$OT_PORTS_WITHHELD" ]]; then
        record_skip "$phase" "OT/ICS vulnerability NSE" \
            "ports $OT_PORTS_WITHHELD are industrial control endpoints; NSE probing is withheld by policy"
    fi

    if [[ -n "$ports" ]]; then
        local scan_type
        (( EUID == 0 )) && scan_type="-sS" || scan_type="-sT"
        [[ -n "$NMAP_VULN_NSE_SCRIPTS" ]] \
            || { error "[$phase] Absolute vulnerability NSE binding is unavailable"; return 1; }
        local -a extra=(-Pn "$scan_type" -p "$ports" \
            --script "$NMAP_VULN_NSE_SCRIPTS" --script-timeout 3m -T3)
        local nmap_rc=0
        if run_nmap_family "$phase" "IPv4 bounded safe NSE vulnerability checks" 4 \
            "$RUN_DIR/targets/open-hosts.ipv4.txt" "$RUN_DIR/raw/nmap-vuln-ipv4" "${extra[@]}"; then
            nmap_rc=0
        else
            nmap_rc=$?
            archive_evidence_files "vuln-ipv4-partial" \
                "$RUN_DIR/raw/nmap-vuln-ipv4.xml" "$RUN_DIR/raw/nmap-vuln-ipv4.nmap" \
                "$RUN_DIR/raw/nmap-vuln-ipv4.gnmap" || return 1
            (( nmap_rc != 65 )) || {
                error "[$phase] Nmap integrity or output validation failed; refusing to complete the phase"
                return "$nmap_rc"
            }
            warn "Optional IPv4 NSE vulnerability checks failed; continuing"
        fi
        if run_nmap_family "$phase" "IPv6 bounded safe NSE vulnerability checks" 6 \
            "$RUN_DIR/targets/open-hosts.ipv6.txt" "$RUN_DIR/raw/nmap-vuln-ipv6" "${extra[@]}"; then
            nmap_rc=0
        else
            nmap_rc=$?
            archive_evidence_files "vuln-ipv6-partial" \
                "$RUN_DIR/raw/nmap-vuln-ipv6.xml" "$RUN_DIR/raw/nmap-vuln-ipv6.nmap" \
                "$RUN_DIR/raw/nmap-vuln-ipv6.gnmap" || return 1
            (( nmap_rc != 65 )) || {
                error "[$phase] Nmap integrity or output validation failed; refusing to complete the phase"
                return "$nmap_rc"
            }
            warn "Optional IPv6 NSE vulnerability checks failed; continuing"
        fi
    fi

    if have nuclei && [[ -s "$httpx_input" ]]; then
        nuclei_templates="$(find_nuclei_templates || true)"
        if [[ -n "$nuclei_templates" ]]; then
            local nuclei_templates_before="" nuclei_templates_after=""
            if ! nuclei_templates_before="$(hash_nuclei_template_tree "$nuclei_templates")"; then
                error "[$phase] Could not hash the complete Nuclei template tree before scanning"
                return 1
            fi
            info "[$phase] Nuclei template snapshot before scanning: $nuclei_templates_before"
            write_nuclei_template_provenance "$nuclei_templates" "$nuclei_templates_before" \
                || return 1
            write_owned_text_file "$nuclei_config" $'{}\n' || return 1
            local nuclei_output="$RUN_DIR/raw/nuclei.jsonl"
            local nuclei_temporary="${nuclei_output}.partial.$$.$RANDOM" nuclei_rc=0
            if run_logged "$phase" "Nuclei non-intrusive web checks" "1h" -- env \
                    -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
                    NO_PROXY='*' no_proxy='*' nuclei -config "$nuclei_config" -l "$httpx_input" \
                    -t "$nuclei_templates" -jsonl -o "$nuclei_temporary" \
                    -type http,ssl -disable-unsigned-templates \
                    -severity info,low,medium,high,critical \
                    -exclude-tags fuzz,dos,bruteforce,default-login,intrusive,headless -rate-limit 50 -concurrency "$JOBS" \
                    -no-stdin -disable-update-check -disable-redirects -no-interactsh -stats -verbose -no-color; then
                nuclei_rc=0
            else
                nuclei_rc=$?
            fi
            finish_optional_output "$phase" "Nuclei non-intrusive web checks" jsonl \
                "$nuclei_temporary" "$nuclei_output" "$nuclei_rc" || return 1
            if [[ -s "$vhost_file" ]]; then
                cap_followup_file "$vhost_file" "$vhost_capped" || return 1
                while IFS=$'\t' read -r host port scheme hostname; do
                    index=$((index + 1))
                    [[ "$host" == *:* ]] && endpoint="[$host]:$port" || endpoint="$host:$port"
                    pinned_url="$scheme://$endpoint/"
                    host_header="$hostname"
                    if [[ ( "$scheme" == http && "$port" != 80 ) || ( "$scheme" == https && "$port" != 443 ) ]]; then
                        host_header="$hostname:$port"
                    fi
                    local nuclei_vhost_output
                    nuclei_vhost_output="$RUN_DIR/raw/nuclei-vhost-$(printf '%04d' "$index").jsonl"
                    local nuclei_vhost_temporary="${nuclei_vhost_output}.partial.$$.$RANDOM" nuclei_vhost_rc=0
                    if run_logged "$phase" "Nuclei virtual host $hostname via $host:$port" "20m" -- env \
                            -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
                            NO_PROXY='*' no_proxy='*' nuclei -config "$nuclei_config" \
                            -u "$pinned_url" -H "Host: $host_header" -sni "$hostname" \
                            -t "$nuclei_templates" -jsonl -o "$nuclei_vhost_temporary" \
                            -type http,ssl -disable-unsigned-templates -severity info,low,medium,high,critical \
                            -exclude-tags fuzz,dos,bruteforce,default-login,intrusive,headless -rate-limit 25 -concurrency "$JOBS" \
                            -no-stdin -disable-update-check -disable-redirects -no-interactsh -stats -verbose -no-color; then
                        nuclei_vhost_rc=0
                    else
                        nuclei_vhost_rc=$?
                    fi
                    finish_optional_output "$phase" "Nuclei virtual host $hostname via $host:$port" jsonl \
                        "$nuclei_vhost_temporary" "$nuclei_vhost_output" "$nuclei_vhost_rc" || return 1
                done <"$vhost_capped"
            fi
            if ! nuclei_templates_after="$(hash_nuclei_template_tree "$nuclei_templates")"; then
                error "[$phase] Could not hash the complete Nuclei template tree after scanning"
                return 1
            fi
            if [[ "$nuclei_templates_after" != "$nuclei_templates_before" ]]; then
                printf '%s\t%s\t%s\t%s\t%s\n' "$(timestamp)" "$phase" \
                    "Nuclei template tree changed during scanning" 65 "$nuclei_templates" \
                    >>"$RUN_DIR/logs/errors.tsv"
                append_event "$phase" "Nuclei template tree changed during scanning" \
                    INVALID_OUTPUT 65 0 "$nuclei_templates"
                archive_evidence_files "vuln-Nuclei-unstable-templates" \
                    "$RUN_DIR/raw/nuclei.jsonl" "$RUN_DIR/raw/nuclei-vhost-"*.jsonl || return 1
                error "[$phase] Nuclei template tree changed during scanning; refusing the phase checkpoint"
                return 1
            fi
            ok "[$phase] Nuclei template tree remained stable: $nuclei_templates_after"
        else
            record_skip "$phase" "Nuclei web checks" "templates are not installed; run nuclei -update-templates before the competition"
        fi
    fi

    if have searchsploit; then
        local xml
        while IFS= read -r -d '' xml; do
            run_optional "$phase" "Offline exploit correlation ${xml##*/}" "10m" -- searchsploit --nmap "$xml"
        done < <(find "$RUN_DIR/raw" -maxdepth 1 -type f -name 'nmap-services-*.xml' -print0)
    fi
}

generate_nmap_html() {
    # These files are derived from the current root-level XML. Remove prior
    # versions first so archived/failed scans cannot retain a stale HTML view.
    rm -f -- "$RUN_DIR"/reports/nmap-*.html "$RUN_DIR"/reports/nmap-*.html.partial.* \
        || return 1
    have xsltproc || return 0
    local xsl="${NMAP_DATA_DIR:+$NMAP_DATA_DIR/nmap.xsl}" xml output temporary command_rc
    [[ -n "$xsl" && -f "$xsl" && ! -L "$xsl" && -r "$xsl" ]] || {
        warn "[report] Pinned Nmap stylesheet is unavailable; skipping optional Nmap HTML rendering"
        return 0
    }
    verify_nmap_runtime || {
        error "[report] Pinned Nmap data changed before HTML rendering"
        return 1
    }
    while IFS= read -r -d '' xml; do
        output="$RUN_DIR/reports/${xml##*/}"
        output="${output%.xml}.html"
        temporary="${output}.partial.$$.$RANDOM"
        command_rc=0
        if run_logged "report" "Nmap HTML ${xml##*/}" "5m" -- \
                xsltproc --nonet -o "$temporary" "$xsl" "$xml"; then
            command_rc=0
        else
            command_rc=$?
        fi
        if (( command_rc != 0 )); then
            archive_evidence_files "report-Nmap-HTML-${xml##*/}-partial" "$temporary" || return 1
            warn "Optional report rendering failed; continuing with the remaining reports"
        elif [[ ! -s "$temporary" ]]; then
            record_invalid_optional_output "report" "Nmap HTML ${xml##*/}" "$temporary"
            archive_evidence_files "report-Nmap-HTML-${xml##*/}-invalid" "$temporary" || return 1
        else
            if ! mv -f -- "$temporary" "$output"; then
                error "[report] Could not promote rendered Nmap HTML: ${output#"$RUN_DIR"/}"
                return 1
            fi
            ok "[report] Promoted rendered Nmap HTML: ${output#"$RUN_DIR"/}"
        fi
    done < <(find "$RUN_DIR/raw" -maxdepth 1 -type f -name '*.xml' -print0)
    verify_nmap_runtime || {
        archive_evidence_files "report-Nmap-HTML-unstable-data" \
            "$RUN_DIR"/reports/nmap-*.html || return 1
        error "[report] Pinned Nmap data changed during HTML rendering"
        return 1
    }
}

generate_reports() {
    extract_inventory || return 1
    build_followup_targets || return 1
    generate_nmap_html || return 1
    python3 -I - "$RUN_DIR" "$RUN_STARTED_UTC" "$PROFILE" <<'PY'
import csv
import html
import json
import sys
from collections import Counter
from pathlib import Path

run_dir = Path(sys.argv[1])
started = sys.argv[2] or "unknown"
profile = sys.argv[3]
targets = run_dir / "targets"
reports = run_dir / "reports"
reports.mkdir(parents=True, exist_ok=True)

with (targets / "services.tsv").open(newline="") as handle:
    services = list(csv.DictReader(handle, delimiter="\t"))
with (targets / "hosts.tsv").open(newline="") as handle:
    hosts = list(csv.DictReader(handle, delimiter="\t"))

errors = []
error_path = run_dir / "logs" / "errors.tsv"
if error_path.exists():
    with error_path.open() as handle:
        for line in handle:
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 5:
                errors.append(parts)

with (reports / "hosts.csv").open("w", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=("address", "family", "hostname", "status"))
    writer.writeheader()
    writer.writerows(hosts)

service_fields = ("address", "hostname", "protocol", "port", "state", "name", "product", "version", "extra", "tunnel", "source")
with (reports / "services.csv").open("w", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=service_fields)
    writer.writeheader()
    writer.writerows(services)
(reports / "services.json").write_text(json.dumps(services, indent=2) + "\n")

protocol_counts = Counter(item["protocol"] for item in services)
port_counts = Counter(f'{item["port"]}/{item["protocol"]}' for item in services)
service_counts = Counter(item["name"] or "unknown" for item in services)

summary = [
    "# CPTC Enumeration Summary",
    "",
    f"- Run: `{run_dir.name}`",
    f"- Started: `{started}`",
    f"- Report generated: `{__import__('datetime').datetime.now(__import__('datetime').timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}`",
    f"- Profile: `{profile}`",
    f"- Hosts represented in scan output: **{len(hosts)}**",
    f"- Open or open-filtered services: **{len(services)}**",
    f"- Logged command failures/timeouts: **{len(errors)}**",
    "",
    "## Protocol totals",
    "",
]
for protocol, count in sorted(protocol_counts.items()):
    summary.append(f"- {protocol}: {count}")
summary.extend(("", "## Most common ports", ""))
for port, count in port_counts.most_common(20):
    summary.append(f"- {port}: {count}")
summary.extend(("", "## Most common identified services", ""))
for name, count in service_counts.most_common(20):
    summary.append(f"- {name}: {count}")
if errors:
    summary.extend(("", "## Command failures and timeouts", ""))
    for event_time, phase, name, code, raw_log, *_ in errors:
        summary.append(f"- `{event_time}` {phase}/{name}: exit {code}; `{raw_log}`")
summary.extend(("", "Review the raw tool output before relying on automated service identification.", ""))
(reports / "summary.md").write_text("\n".join(summary))

rows = []
for item in services:
    product = " ".join(part for part in (item["product"], item["version"], item["extra"]) if part)
    rows.append(
        "<tr>" + "".join(
            f"<td>{html.escape(str(value))}</td>"
            for value in (item["address"], item["hostname"], item["protocol"], item["port"], item["state"], item["name"], product)
        ) + "</tr>"
    )
document = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>CPTC enumeration report</title>
<style>body{{font-family:system-ui,sans-serif;max-width:1500px;margin:2rem auto;padding:0 1rem;background:#111827;color:#e5e7eb}}
table{{border-collapse:collapse;width:100%;font-size:.9rem}}th,td{{border:1px solid #374151;padding:.45rem;text-align:left}}
th{{background:#1f2937;position:sticky;top:0}}tr:nth-child(even){{background:#182131}}code{{color:#93c5fd}}</style></head>
<body><h1>CPTC Enumeration Report</h1><p>Run <code>{html.escape(run_dir.name)}</code>; {len(hosts)} hosts; {len(services)} open/open-filtered services; {len(errors)} command failures.</p>
<table><thead><tr><th>Address</th><th>Hostname</th><th>Protocol</th><th>Port</th><th>State</th><th>Service</th><th>Product/version</th></tr></thead>
<tbody>{''.join(rows)}</tbody></table></body></html>"""
(reports / "index.html").write_text(document)
print(f"Reports written to {reports}")
PY
    local report_status=$?
    (( report_status == 0 )) || return "$report_status"
    write_artifact_manifest
}

write_artifact_manifest() {
    # Logs and state continue changing as the runner records phase completion.
    # Hash the frozen scope, raw evidence, derived inventory, and final reports.
    python3 -I - "$RUN_DIR" <<'PY'
import hashlib
import os
import sys
from pathlib import Path

run_dir = Path(sys.argv[1]).resolve()
manifest_path = run_dir / "reports" / "SHA256SUMS"
entries = []
def sha256_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

for directory in ("scope", "raw", "targets", "reports"):
    root = run_dir / directory
    if root.is_symlink():
        raise RuntimeError(f"covered artifact root is a symbolic link: {directory}")
    if not root.exists():
        continue
    if not root.is_dir():
        raise RuntimeError(f"covered artifact root is not a directory: {directory}")
    for path in sorted(root.rglob("*")):
        if path == manifest_path:
            continue
        if path.is_symlink():
            raise RuntimeError(f"symbolic links are not allowed in covered artifacts: {path.relative_to(run_dir)}")
        if path.is_dir():
            continue
        if not path.is_file():
            raise RuntimeError(f"unsupported file type in covered artifacts: {path.relative_to(run_dir)}")
        try:
            path.resolve().relative_to(run_dir)
        except (OSError, ValueError) as exc:
            raise RuntimeError(f"artifact path escapes the run directory: {path}") from exc
        entries.append(f"{sha256_file(path)}  {path.relative_to(run_dir)}")
temporary_path = manifest_path.with_name(f".{manifest_path.name}.tmp.{os.getpid()}")
temporary_path.write_text("\n".join(entries) + "\n", encoding="utf-8")
os.replace(temporary_path, manifest_path)
print(f"Artifact checksums written to {manifest_path}")
PY
}

phase_report() { generate_reports; }

run_phase() {
    local phase="$1" function_name="$2"
    phase_requested "$phase" || return 0
    if (( RESUME_MODE )) && [[ "$phase" != report ]] && phase_done "$phase"; then
        info "[$phase] already completed; resume is skipping it"
        return 0
    fi
    if (( RESUME_MODE )) && [[ "$phase" == report ]] && phase_done "$phase"; then
        info "[report] refreshing reports and artifact checksums for this resume invocation"
        rm -f -- "$RUN_DIR/.state/report.done"
    fi
    if (( RESUME_MODE && DRY_RUN == 0 )); then
        invalidate_downstream_phases "$phase"
    fi
    info "========== phase: $phase =========="
    if "$function_name"; then
        if (( DRY_RUN )); then
            ok "Dry-run phase preview completed: $phase"
        else
            if ! mark_phase_done "$phase"; then
                error "Could not persist the completion checkpoint for phase: $phase"
                return 1
            fi
            ok "Phase completed: $phase"
        fi
    else
        error "Phase failed: $phase"
        return 1
    fi
}

cleanup_children() {
    local signal="${1:-EXIT}"
    if [[ "$signal" != EXIT ]]; then
        warn "Received $signal; stopping child processes"
        jobs -pr | xargs -r kill 2>/dev/null || true
    fi
}

execute_run() {
    validate_run_options
    local command_name
    for command_name in python3 timeout tee flock env find readlink cmp mktemp; do
        have "$command_name" || die "required command is missing: $command_name (run '$SCRIPT_NAME install --all')"
    done
    if (( DRY_RUN == 0 )) && ! have nmap; then
        die "required command is missing: nmap (run '$SCRIPT_NAME install --all')"
    fi

    RUN_STARTED_UTC="$(timestamp)"
    if (( RESUME_MODE == 0 )); then
        OUTPUT_ROOT="$(absolute_path "$OUTPUT_ROOT")"
        mkdir -p -- "$OUTPUT_ROOT"
        RUN_DIR="$OUTPUT_ROOT/$(date -u '+%Y%m%dT%H%M%SZ')-$LABEL"
        [[ ! -e "$RUN_DIR" ]] || RUN_DIR="${RUN_DIR}-$$"
        mkdir -p -- "$RUN_DIR/.state"
        chmod 700 "$RUN_DIR" "$RUN_DIR/.state"
    else
        RUN_DIR="$(absolute_path "$RUN_DIR")"
        [[ -d "$RUN_DIR/.state" ]] || die "not a CPTC run directory: $RUN_DIR"
    fi

    validate_run_directory_layout "$RESUME_MODE"
    if (( RESUME_LOCK_HELD == 0 )); then
        exec 9>"$RUN_DIR/.state/run.lock"
        flock -n 9 || die "another process is already using this run directory"
    fi
    trap 'cleanup_children INT; exit 130' INT
    trap 'cleanup_children TERM; exit 143' TERM
    trap 'cleanup_children EXIT' EXIT

    init_logging
    validate_covered_artifact_layout \
        || die "run directory contains unsafe covered artifact paths"
    if (( RESUME_MODE == 0 )); then
        write_initial_scope_files
    else
        [[ -s "$RUN_DIR/scope/requested.txt" ]] || die "resume directory has no frozen scope input"
    fi

    if (( RESUME_MODE )); then
        verify_frozen_scope
        local artifact_status=0
        if verify_artifact_manifest; then
            ok "Prior artifact manifest verified; completed phase checkpoints may be reused"
            preflight_recorded_nmap_runtime \
                || die "Nmap data changed or is unavailable; the existing checksum baseline was preserved"
            verify_recorded_nuclei_template_provenance \
                || die "Nuclei templates changed since this run was frozen; start a new run"
            retire_verified_artifact_manifest
        else
            artifact_status=$?
            if (( artifact_status == 2 )); then
                invalidate_all_phase_checkpoints
                reset_interrupted_current_evidence \
                    || die "could not retire interrupted current evidence before rebuilding"
            else
                die "prior artifact verification failed; the existing checksum baseline was preserved and Resume was refused"
            fi
        fi
    else
        normalize_scope
    fi
    (( RESUME_MODE )) || save_run_settings
    prepare_nmap_runtime
    capture_environment || die "could not capture the runtime environment and tool provenance"
    info "Profile: $PROFILE; phases: $PHASES; packet ceiling: $MAX_RATE/s"
    (( EUID == 0 )) || warn "Root privileges improve SYN, UDP, and OS detection coverage"

    local failed=0 index
    local -a phase_plan=(
        discovery phase_discovery
        tcp phase_tcp
        udp phase_udp
        services phase_services
        followups phase_followups
        vuln phase_vuln
        report phase_report
    )
    for ((index = 0; index < ${#phase_plan[@]}; index += 2)); do
        if ! run_phase "${phase_plan[index]}" "${phase_plan[index + 1]}"; then
            failed=1
            warn "Stopping before downstream phases so resume cannot accept stale derived evidence"
            break
        fi
    done

    if (( failed )); then
        warn "Run completed with one or more failed phases. See $RUN_DIR/logs/errors.tsv"
        return 1
    fi
    local logged_error_count=0
    logged_error_count="$(wc -l <"$RUN_DIR/logs/errors.tsv")"
    if (( DRY_RUN )); then
        ok "Dry run complete; no scanner commands were executed: $RUN_DIR"
    elif (( logged_error_count > 0 )); then
        warn "Enumeration finished with $logged_error_count logged command failure(s) across the run history; review logs/errors.tsv"
        ok "Enumeration artifacts are available: $RUN_DIR"
    else
        ok "Enumeration complete: $RUN_DIR"
    fi
    if [[ -f "$RUN_DIR/reports/summary.md" ]]; then
        info "Summary: $RUN_DIR/reports/summary.md"
    fi
    return 0
}

report_existing() {
    (( $# == 1 )) || die "report requires exactly one RUN_DIR"
    RUN_DIR="$(absolute_path "$1")"
    [[ -d "$RUN_DIR/raw" && -d "$RUN_DIR/scope" && -d "$RUN_DIR/.state" ]] \
        || die "not a CPTC run directory: $RUN_DIR"
    validate_run_directory_layout 1
    validate_covered_artifact_layout \
        || die "run directory contains unsafe covered artifact paths"
    exec 9>"$RUN_DIR/.state/run.lock"
    flock -n 9 || die "another process is already using this run directory"
    trap 'cleanup_children INT; exit 130' INT
    trap 'cleanup_children TERM; exit 143' TERM
    trap 'cleanup_children EXIT' EXIT
    RUN_STARTED_UTC="unknown"
    verify_resume_settings
    [[ -r "$RUN_DIR/.state/profile" ]] && PROFILE="$(<"$RUN_DIR/.state/profile")" || PROFILE="unknown"
    DRY_RUN=0
    init_logging
    validate_covered_artifact_layout \
        || die "run directory contains unsafe covered artifact paths"
    verify_frozen_scope
    local artifact_status=0
    if verify_artifact_manifest; then
        ok "Prior artifact manifest verified before report regeneration"
        if [[ -f "$RUN_DIR/scope/nmap-data.json" && ! -L "$RUN_DIR/scope/nmap-data.json" ]]; then
            preflight_recorded_nmap_runtime \
                || die "Nmap data changed or is unavailable; the existing checksum baseline was preserved"
            prepare_nmap_runtime
        elif [[ -e "$RUN_DIR/scope/nmap-data.json" || -L "$RUN_DIR/scope/nmap-data.json" ]]; then
            die "Nmap data provenance is not a safe regular file; the existing checksum baseline was preserved"
        fi
        retire_verified_artifact_manifest
    else
        artifact_status=$?
        if (( artifact_status != 2 )); then
            die "prior artifact verification failed; refusing to replace its checksum baseline"
        fi
        warn "No prior artifact manifest exists; generating the first report from the available scoped evidence"
        if [[ -f "$RUN_DIR/scope/nmap-data.json" && ! -L "$RUN_DIR/scope/nmap-data.json" ]]; then
            preflight_recorded_nmap_runtime \
                || die "Nmap data changed or is unavailable; report regeneration was refused"
            prepare_nmap_runtime
        elif [[ -e "$RUN_DIR/scope/nmap-data.json" || -L "$RUN_DIR/scope/nmap-data.json" ]]; then
            die "Nmap data provenance is not a safe regular file; report regeneration was refused"
        fi
    fi
    generate_reports
    ok "Report refreshed: $RUN_DIR/reports/index.html"
}

# ---------------------------------------------------------------------------
# Native activity logging
#
# Turns on the operating system's own auditing so the operator's actions on a
# competition workstation are recorded for the client report and for
# deconfliction.  This logs US, not a target.  Everything here is reversible
# with `logging revert`, and `logging verify` proves each facility is actually
# recording rather than merely configured.
#
# The guiding lesson from testing: configuration state lies.  On the
# development box `systemctl is-active auditd` reported active and
# `auditctl -l` listed four loaded rules while `auditctl -s` reported
# `enabled 0`, audit.log was 22 hours stale and `ausearch -ts recent` returned
# nothing at all.  Rules can be loaded into a subsystem that is switched off.
# So every check below is a round trip: emit a marker, then read it back.
# ---------------------------------------------------------------------------

readonly CPTC_SUDOERS_DROPIN="/etc/sudoers.d/99-cptc-logging"
readonly CPTC_AUDIT_RULES="/etc/audit/rules.d/99-cptc.rules"
readonly CPTC_AUDIT_KEY="cptc-exec"
readonly CPTC_BASHRC_BEGIN="# ---- CPTC-LOGGING-BEGIN (remove this block to revert) ----"
readonly CPTC_BASHRC_END="# ---- CPTC-LOGGING-END ----"

# The operator is whoever invoked sudo, never root.  Under sudo, $HOME is
# root's home and $(id -u) is 0, so a rule keyed on either silently matches
# nothing the operator does and a transcript lands in the wrong home.
logging_operator_name() { printf '%s' "${SUDO_USER:-$(id -un)}"; }
logging_operator_uid() { printf '%s' "${SUDO_UID:-$(id -u)}"; }
logging_operator_home() {
    local entry
    entry="$(getent passwd "$(logging_operator_name)" 2>/dev/null)" || return 1
    printf '%s' "$(printf '%s' "$entry" | cut -d: -f6)"
}
logging_dir() { printf '%s/.cptc-logs' "$(logging_operator_home)"; }

# Runs a command as the operator even when we are root.
as_operator() {
    if (( EUID == 0 )) && [[ -n "${SUDO_USER:-}" ]]; then
        runuser -u "$SUDO_USER" -- "$@"
    else
        "$@"
    fi
}

logging_enable_shell() {
    local home dir rc marker
    home="$(logging_operator_home)" || { error "cannot resolve the operator's home directory"; return 1; }
    dir="$(logging_dir)"
    rc="$home/.bashrc"
    [[ -f "$rc" ]] || as_operator touch "$rc" || { error "cannot create $rc"; return 1; }

    as_operator mkdir -p "$dir/session" || return 1
    as_operator chmod 700 "$dir" "$dir/session" || return 1

    # The session launcher.  The four guards are what keep this from recursing
    # forever and from breaking scp, rsync, sftp and `ssh host command`, all of
    # which run a non-interactive shell that must never be wrapped.
    as_operator tee "$dir/session-log.sh" >/dev/null <<'LAUNCHER'
# Started from ~/.bashrc.  Replaces the shell with one running under script(1).
__cptc_session_log() {
    local dir="${1:-$HOME/.cptc-logs/session}" base
    case $- in *i*) ;; *) return 0 ;; esac            # G1 interactive only
    [[ -t 0 && -t 1 ]] || return 0                    # G2 a real tty both ends
    [[ -n "${CPTC_SESSION_LOG:-}" ]] && return 0      # G3 already inside one
    [[ -n "${SSH_ORIGINAL_COMMAND:-}" ]] && return 0  # G4 ForceCommand
    command -v script >/dev/null 2>&1 || return 0
    mkdir -p "$dir" 2>/dev/null || return 0
    chmod 700 "$dir" 2>/dev/null
    base="$dir/session-$(date -u +%Y%m%dT%H%M%SZ)-$$"
    CPTC_SESSION_LOG="$base.log"
    export CPTC_SESSION_LOG
    umask 077
    logger -t cptc-session -p user.notice \
        "session-start user=$(id -un) tty=$(tty) log=$base.log" 2>/dev/null
    # -f flushes after every write so a kill -9 keeps the transcript;
    # -o caps output so a runaway scan cannot fill the disk.
    exec script -q -f -a -T "$base.timing" -O "$base.log" -o 512m \
        -c "${SHELL:-/bin/bash} -i"
}
LAUNCHER
    as_operator chmod 600 "$dir/session-log.sh" || return 1

    if as_operator grep -qF 'CPTC-LOGGING-BEGIN' "$rc" 2>/dev/null; then
        info "shell logging block already present in $rc"
        return 0
    fi

    # HISTCONTROL is cleared deliberately.  The distro default `ignoreboth`
    # silently drops duplicate commands AND any command typed with a leading
    # space -- measured: three history entries collapsed to one, and the
    # space-prefixed one disappeared.  That is the exact habit used to keep a
    # credential out of history, so for an audit trail it has to go.  The
    # trade-off is real and runs the other way: a password typed with a
    # leading space now DOES land in the history file.  See `logging notes`.
    as_operator tee -a "$rc" >/dev/null <<LOGGINGBLOCK
$CPTC_BASHRC_BEGIN
HISTFILE="\$HOME/.bash_history"
HISTTIMEFORMAT='%Y-%m-%dT%H:%M:%S%z '
HISTSIZE=1000000
HISTFILESIZE=1000000
HISTCONTROL=
HISTIGNORE=
shopt -s histappend
shopt -s cmdhist
if [[ \${PROMPT_COMMAND@a} == *a* ]]; then
    PROMPT_COMMAND+=( 'history -a' )
else
    PROMPT_COMMAND="history -a\${PROMPT_COMMAND:+; \$PROMPT_COMMAND}"
fi
[[ -r "\$HOME/.cptc-logs/session-log.sh" ]] \\
    && . "\$HOME/.cptc-logs/session-log.sh" \\
    && __cptc_session_log
$CPTC_BASHRC_END
LOGGINGBLOCK
    ok "shell history hardening and session transcripts enabled for $(logging_operator_name)"
    info "they take effect in newly opened shells (or run: source ~/.bashrc)"
}

logging_enable_auditd() {
    local uid rules
    (( EUID == 0 )) || { warn "auditd execve auditing needs root; skipped"; return 0; }
    have auditctl || { warn "auditctl is not installed; install the auditd package to get the authoritative trail"; return 0; }
    uid="$(logging_operator_uid)"
    [[ "$uid" =~ ^[0-9]+$ ]] || { error "could not resolve the operator uid"; return 1; }
    if [[ "$uid" == 0 ]]; then
        warn "operator uid resolved to 0; an auid rule keyed on root would miss the operator's own commands"
    fi

    # auid is the login uid, which survives su/sudo, so this follows the
    # operator through privilege changes.  auid!=unset drops kernel threads.
    rules="-a always,exit -F arch=b64 -S execve -F auid=$uid -F auid!=unset -k $CPTC_AUDIT_KEY
-a always,exit -F arch=b32 -S execve -F auid=$uid -F auid!=unset -k $CPTC_AUDIT_KEY"

    # The subsystem can be administratively disabled while rules load fine.
    local enabled
    enabled="$(auditctl -s 2>/dev/null | tr ' ' '\n' | grep -A1 '^enabled$' | tail -1)"
    if [[ "$enabled" == 0 ]]; then
        warn "the audit subsystem is loaded but switched off (enabled 0); turning it on"
        auditctl -e 1 >/dev/null 2>&1 || warn "could not enable the audit subsystem"
    fi

    local line
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        # shellcheck disable=SC2086
        auditctl $line >/dev/null 2>&1 || warn "could not load audit rule: $line"
    done <<<"$rules"

    if [[ -d /etc/audit/rules.d ]]; then
        printf '# CPTC operator activity auditing. Remove this file to revert.\n%s\n' "$rules" \
            >"$CPTC_AUDIT_RULES" || warn "could not persist audit rules"
        chmod 640 "$CPTC_AUDIT_RULES" 2>/dev/null || true
        info "audit rules persisted to $CPTC_AUDIT_RULES"
    else
        warn "/etc/audit/rules.d is absent; audit rules are active now but will not survive a reboot"
    fi
    ok "auditd execve auditing enabled for uid $uid (key $CPTC_AUDIT_KEY)"
}

logging_enable_sudo_io() {
    local temporary
    (( EUID == 0 )) || { warn "sudo I/O logging needs root; skipped"; return 0; }
    have visudo || { warn "visudo is not available; refusing to touch sudoers"; return 0; }
    [[ -d /etc/sudoers.d ]] || { warn "/etc/sudoers.d is absent; skipping sudo I/O logging"; return 0; }

    temporary="$(mktemp)" || return 1
    printf '%s\n' \
        '# CPTC operator activity logging. Remove this file to revert.' \
        'Defaults log_input, log_output' \
        'Defaults iolog_dir=/var/log/sudo-io' \
        'Defaults!/usr/bin/sudoreplay !log_output' \
        'Defaults!/usr/sbin/visudo !log_output' \
        >"$temporary"

    # A malformed sudoers file locks the operator out of sudo entirely, so it
    # is validated in place before it is ever installed.
    if ! visudo -cqf "$temporary" >/dev/null 2>&1; then
        rm -f -- "$temporary"
        error "the generated sudoers snippet failed validation; sudo was left untouched"
        return 1
    fi
    install -m 0440 -o root -g root "$temporary" "$CPTC_SUDOERS_DROPIN" || {
        rm -f -- "$temporary"; error "could not install $CPTC_SUDOERS_DROPIN"; return 1; }
    rm -f -- "$temporary"
    mkdir -p /var/log/sudo-io 2>/dev/null || true
    chmod 700 /var/log/sudo-io 2>/dev/null || true
    ok "sudo I/O logging enabled (sessions under /var/log/sudo-io, replay with sudoreplay)"
    warn "sudo I/O logs capture full terminal output, which can include target data and anything typed"
}

logging_enable_journal() {
    (( EUID == 0 )) || { warn "journald persistence needs root; skipped"; return 0; }
    have journalctl || { warn "journalctl is not available; skipped"; return 0; }
    if [[ -d /var/log/journal ]]; then
        info "journald storage is already persistent"
    else
        mkdir -p /var/log/journal || { warn "could not create /var/log/journal"; return 0; }
        chmod 2755 /var/log/journal 2>/dev/null || true
        journalctl --flush >/dev/null 2>&1 || warn "could not flush the journal to disk"
        ok "journald persistence enabled (/var/log/journal)"
    fi
    if have accton && [[ -d /var/log/account || -d /var/account ]]; then
        local pacct=/var/log/account/pacct
        [[ -d /var/log/account ]] || pacct=/var/account/pacct
        if accton "$pacct" >/dev/null 2>&1; then
            ok "process accounting enabled ($pacct)"
        else
            warn "could not enable process accounting"
        fi
    fi
}

# Round-trip proof that each facility is recording, not merely configured.
logging_verify() {
    local failures=0 nonce marker dir
    nonce="cptcmarker$$$(date -u +%s)"
    dir="$(logging_dir)"
    info "verifying that each facility actually records (not just that it is configured)"

    # auditd: emit a uniquely-argumented execve, then read it back by key.
    if have auditctl && (( EUID == 0 )); then
        local enabled
        enabled="$(auditctl -s 2>/dev/null | tr ' ' '\n' | grep -A1 '^enabled$' | tail -1)"
        if [[ "$enabled" != 1 ]]; then
            error "auditd: subsystem reports enabled=$enabled, so nothing is being recorded"
            failures=$((failures + 1))
        elif have ausearch; then
            as_operator /bin/true "$nonce" 2>/dev/null || true
            sleep 1
            if ausearch -k "$CPTC_AUDIT_KEY" -ts recent 2>/dev/null | grep -qF "$nonce"; then
                ok "auditd: marker recovered from the audit trail"
            else
                error "auditd: rules are loaded but the marker was not recorded"
                failures=$((failures + 1))
            fi
        else
            warn "auditd: ausearch is unavailable, cannot round-trip the trail"
        fi
    else
        warn "auditd: not verifiable without root and auditctl"
    fi

    # bash history: the file must exist, be appendable and carry timestamps.
    local histfile
    histfile="$(logging_operator_home)/.bash_history"
    if [[ -f "$histfile" ]]; then
        if grep -qE '^#[0-9]{9,}' "$histfile" 2>/dev/null; then
            ok "bash history: timestamped entries present"
        else
            warn "bash history: no timestamp lines yet (open a new shell and run a command)"
        fi
    else
        warn "bash history: $histfile does not exist yet"
    fi

    # session transcripts: the launcher must be installed and sourced.
    if [[ -r "$dir/session-log.sh" ]] \
        && grep -qF 'CPTC-LOGGING-BEGIN' "$(logging_operator_home)/.bashrc" 2>/dev/null; then
        local count
        count="$(find "$dir/session" -name 'session-*.log' 2>/dev/null | wc -l)"
        ok "session transcripts: launcher installed and sourced ($count transcript(s) so far)"
        (( count == 0 )) && info "transcripts appear once the operator opens a new interactive shell"
    else
        error "session transcripts: launcher is not installed or not sourced from .bashrc"
        failures=$((failures + 1))
    fi

    # sudo I/O logging
    if [[ -f "$CPTC_SUDOERS_DROPIN" ]]; then
        if [[ -d /var/log/sudo-io ]]; then
            ok "sudo I/O logging: configured, iolog directory present"
        else
            warn "sudo I/O logging: configured but /var/log/sudo-io is missing"
        fi
    else
        warn "sudo I/O logging: not configured"
    fi

    # journald persistence
    if [[ -d /var/log/journal ]]; then
        ok "journald: persistent storage present"
    else
        warn "journald: storage is volatile; logs are lost on reboot"
    fi

    if (( failures )); then
        error "$failures logging facility check(s) failed; the activity trail is incomplete"
        return 1
    fi
    ok "every checked logging facility is recording"
}

logging_revert() {
    local home rc
    home="$(logging_operator_home)" || { error "cannot resolve the operator's home"; return 1; }
    rc="$home/.bashrc"
    if [[ -f "$rc" ]] && grep -qF 'CPTC-LOGGING-BEGIN' "$rc"; then
        if as_operator sed -i "/${CPTC_BASHRC_BEGIN//\//\\/}/,/${CPTC_BASHRC_END//\//\\/}/d" "$rc"; then
            ok "removed the logging block from $rc"
        else
            warn "could not edit $rc"
        fi
    else
        info "no logging block present in $rc"
    fi
    as_operator rm -f -- "$home/.cptc-logs/session-log.sh" 2>/dev/null || true

    if (( EUID == 0 )); then
        if have auditctl; then
            if auditctl -D -k "$CPTC_AUDIT_KEY" >/dev/null 2>&1; then
                ok "removed runtime audit rules keyed $CPTC_AUDIT_KEY"
            fi
        fi
        [[ -f "$CPTC_AUDIT_RULES" ]] && { rm -f -- "$CPTC_AUDIT_RULES"; ok "removed $CPTC_AUDIT_RULES"; }
        [[ -f "$CPTC_SUDOERS_DROPIN" ]] && { rm -f -- "$CPTC_SUDOERS_DROPIN"; ok "removed $CPTC_SUDOERS_DROPIN"; }
    else
        warn "re-run under sudo to also remove the auditd rules and sudoers drop-in"
    fi
    info "collected logs are left in place; remove them yourself when the engagement is reported"
}

logging_action() {
    local mode="${1:-enable}"
    case "$mode" in
        enable)
            info "enabling native activity logging for operator $(logging_operator_name)"
            (( EUID == 0 )) || warn "running without root: auditd, sudo I/O and journald persistence will be skipped"
            logging_enable_shell || return 1
            logging_enable_auditd || return 1
            logging_enable_sudo_io || return 1
            logging_enable_journal || return 1
            warn "these logs record the operator's own activity and can contain sensitive output; they are mode 0600/0700"
            info "run '$0 logging verify' to prove the facilities are recording"
            ;;
        verify) logging_verify ;;
        revert) logging_revert ;;
        *) die "logging takes enable, verify, or revert" ;;
    esac
}

main() {
    (( BASH_VERSINFO[0] >= 5 )) || die "Bash 5 or newer is required"
    local subcommand="${1:-help}"
    [[ $# -gt 0 ]] && shift || true
    case "$subcommand" in
        help|-h|--help) usage ;;
        install) install_packages "$@" ;;
        doctor) (( $# == 0 )) || die "doctor takes no arguments"; doctor ;;
        logging) (( $# <= 1 )) || die "logging takes at most one argument"; logging_action "${1:-enable}" ;;
        run)
            set_run_defaults
            parse_run_args "$@"
            execute_run
            ;;
        resume)
            (( $# >= 1 )) || die "resume requires RUN_DIR"
            set_run_defaults
            RESUME_MODE=1
            RUN_DIR="$1"
            shift
            RUN_DIR="$(absolute_path "$RUN_DIR")"
            [[ -d "$RUN_DIR/.state" ]] || die "not a CPTC run directory: $RUN_DIR"
            have flock || die "required command is missing: flock"
            validate_run_directory_layout 1
            validate_covered_artifact_layout \
                || die "run directory contains unsafe covered artifact paths"
            exec 9>"$RUN_DIR/.state/run.lock"
            flock -n 9 || die "another process is already using this run directory"
            RESUME_LOCK_HELD=1
            load_resume_settings
            parse_run_args "$@"
            execute_run
            ;;
        report) report_existing "$@" ;;
        *) die "unknown command: $subcommand (try '$SCRIPT_NAME help')" ;;
    esac
}

main "$@"
