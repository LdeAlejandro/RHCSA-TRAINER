#!/usr/bin/env bash
# RHCSA mini-trainer — by Alejandro Amoroso
set -euo pipefail

# ===== Colors (portable via tput) =====
if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
  RED=$(tput setaf 1); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); CYAN=$(tput setaf 6); RESET=$(tput sgr0)
else
  RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

# ===== Global workspace (tmpfs) =====
RHCSA_SHM_DIR="${RHCSA_SHM_DIR:-/dev/shm/rhcsa-trainer}"
mkdir -p "$RHCSA_SHM_DIR"

# ===== Start monitored shell (robust) =====
start_monitor() {
  RHCSA_SHM_DIR="${RHCSA_SHM_DIR:-/dev/shm/rhcsa-trainer}"
  mkdir -p "$RHCSA_SHM_DIR"

  local LOG="$RHCSA_SHM_DIR/cmd.log"
  local RCFILE="$RHCSA_SHM_DIR/mon.rc"
  : > "$LOG"

  # RC file that sets up DEBUG trap
  cat >"$RCFILE" <<EOFRC
# RHCSA trainer rcfile
echo "[rhcsa] monitored shell active"
LOG_FILE="$LOG"
trap 'printf "%s\n" "\$BASH_COMMAND" >> "\$LOG_FILE"' DEBUG
PS1="[RHCSA] \u@\h:\w\$ "
EOFRC

  # Start shell with rcfile explicitly loaded
  exec /usr/bin/bash --rcfile "$RCFILE" -i
}

# ===== Exercise Q1 =====
Q1_DESC="Use vim to create and save a file hello.txt containing 'hello world'"

check_Q1() {
  local LOG="$RHCSA_SHM_DIR/cmd.log"

  # 1) File exists with exact content
  [[ -f hello.txt ]] && grep -qx "hello world" hello.txt || return 1

  # 2) User actually executed vi|vim hello.txt inside the monitored shell
  if [[ -f "$LOG" ]] && grep -Eq '^(vi|vim)[[:space:]]+(\./)?hello\.txt([[:space:]]|$)' "$LOG"; then
    return 0
  else
    echo "[FAIL] File is correct, but I did not see 'vim hello.txt' in the monitored session (run via 'rhcsa-trainer start')."
    return 1
  fi
}

# ===== Exercise Q2 =====
Q2_DESC="Generate an SSH key and configure key-based login to remote server master-server@192.168.15.14"

check_Q2() {
  # 1) Require at least one public key locally
  if ! ls ~/.ssh/*.pub >/dev/null 2>&1; then
    echo "[FAIL] No public key found in ~/.ssh"
    return 1
  fi

  # 2) Try passwordless SSH. BatchMode=yes ensures failure if a password is needed.
  if ssh -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o PubkeyAuthentication=yes \
        -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=5 \
        master-server@192.168.15.14 true 2>/dev/null; then
    return 0
  else
    echo "[FAIL] Could not log in without password. Did you run ssh-copy-id?"
    return 1
  fi
}

# ===== Infra =====
TASKS=(Q1 Q2)
declare -A STATUS

evaluate_all() {
  for id in "${TASKS[@]}"; do
    if "check_${id}"; then
      STATUS[$id]="${GREEN}PASSED${RESET}"
    else
      STATUS[$id]="${RED}PENDING${RESET}"
    fi
  done
}

reset_all() {
  for id in "${TASKS[@]}"; do STATUS[$id]="${YELLOW}PENDING${RESET}"; done
  rm -f hello.txt
  rm -f "$RHCSA_SHM_DIR"/cmd.log 2>/dev/null || true
  echo ">> Progress reset: all tasks are now ${YELLOW}PENDING${RESET}."
}

board() {
  echo -e "${CYAN}==== RHCSA Trainer ====${RESET}"
  for id in "${TASKS[@]}"; do
    local desc_var="${id}_DESC"
    printf "%b%-3s%b | %b | %s\n" "$YELLOW" "$id" "$RESET" "${STATUS[$id]}" "${!desc_var}"
  done
}

usage() {
  cat <<EOF
Usage: rhcsa-trainer [command]

Commands:
  start   open monitored shell
  board   show exercise status
  eval    re-run checks
  reset   reset progress
  help    this help
EOF
}

case "${1-}" in
  start) start_monitor ;;
  eval)  evaluate_all; board ;;
  board|"") evaluate_all; board ;;
  reset) reset_all; board ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
