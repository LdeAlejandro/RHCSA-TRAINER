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

  mkdir -p ~/trainer/Documents
  mkdir -p ~/trainer/DocumentBackup
  mkdir -p ~/trainer/files
  tee ~/trainer/files/move_me.txt <<EOF
  file and content created: move me to document and copy me to backup
EOF

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
  local REMOTE_USER="${Q2_USER:-master-server}"
  local REMOTE_HOST="${Q2_HOST:-192.168.15.14}"

  # 1) Local public key must exist
  local PUBKEY
  PUBKEY="$(find ~/.ssh -maxdepth 1 -type f -name '*.pub' -print -quit)"
  if [[ -z "$PUBKEY" ]]; then
    echo "[FAIL] No public key found under ~/.ssh (*.pub). Generate one with: ssh-keygen -t rsa -b 4096"
    return 1
  fi

  # 2) Quick reachability check (optional but helpful)
  if ! ping -c1 -W1 "$REMOTE_HOST" >/dev/null 2>&1; then
    echo "[FAIL] Host $REMOTE_HOST not reachable (ping failed)."
    return 1
  fi

  # 3) Try passwordless SSH (no prompts; fail fast if password is needed)
  if ssh -o BatchMode=yes \
         -o PasswordAuthentication=no \
         -o PubkeyAuthentication=yes \
         -o StrictHostKeyChecking=accept-new \
         -o ConnectTimeout=5 \
         "${REMOTE_USER}@${REMOTE_HOST}" true 2>/dev/null; then
    echo "[OK] Passwordless SSH is working for ${REMOTE_USER}@${REMOTE_HOST}."
    return 0
  fi

  # 4) Diagnose why it failed: is our key present on the remote?
  local KEY_FINGERPRINT
  KEY_FINGERPRINT="$(cut -d' ' -f2 < "$PUBKEY")"

  if ssh -o ConnectTimeout=5 "${REMOTE_USER}@${REMOTE_HOST}" \
       "test -f ~/.ssh/authorized_keys && grep -q \"$KEY_FINGERPRINT\" ~/.ssh/authorized_keys" 2>/dev/null; then
    echo "[FAIL] Key is present on remote but auth still failed."
    echo "       Likely permissions/contexts. On the remote, try:"
    echo "       chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && restorecon -Rv ~/.ssh"
  else
    echo "[FAIL] Your public key is NOT on the remote."
    echo "       Fix with: ssh-copy-id -i \"$PUBKEY\" ${REMOTE_USER}@${REMOTE_HOST}"
  fi

  return 1
}

# ===== Exercise Q3 =====
Q3_DESC="Check recent system logs"

check_Q3() {
  local LOG="$RHCSA_SHM_DIR/cmd.log"

  # 1) Verifica se houve atividade registrada
  [[ -f "$LOG" ]] || { echo "[FAIL] No monitored session found. Run via 'rhcsa-trainer start'."; return 1; }

  # 2) Procura comandos usados para visualizar logs
  if grep -Eq 'journalctl[[:space:]]+-xe' "$LOG" || grep -Eq 'cat[[:space:]]+/var/log/secure' "$LOG" || grep -Eq 'vim[[:space:]]+/var/log/secure' "$LOG" || grep -Eq 'vi[[:space:]]+/var/log/secure' "$LOG"; then
    echo "[OK] Log inspection command detected."
    return 0
  else
    echo "[FAIL] Did not detect 'journalctl -xe' or 'cat /var/log/secure' in monitored session."
    echo "       Try again: run 'rhcsa-trainer start' and use one of those commands."
    return 1
  fi
}

# ===== Exercise Q4 =====
Q4_DESC="Move the file from the files directory to the Documents directory, then copy it to the DocumentBackup directory — all located inside the user’s home directory."

check_Q4() {
  local SRC_DIR="$HOME/trainer/files"
  local DOC_DIR="$HOME/trainer/Documents"
  local BAK_DIR="$HOME/trainer/DocumentBackup"
  local FILENAME="move_me.txt"

  # File should NOT exist in source anymore (it was moved)
  if [[ -e "$SRC_DIR/$FILENAME" ]]; then
    echo "[FAIL] File still exists in $SRC_DIR — it should have been moved."
    return 1
  fi

  # File must exist in Documents
  if [[ ! -e "$DOC_DIR/$FILENAME" ]]; then
    echo "[FAIL] File not found in $DOC_DIR — move step missing."
    return 1
  fi

  # File must exist in DocumentBackup as a copy
  if [[ ! -e "$BAK_DIR/$FILENAME" ]]; then
    echo "[FAIL] File not found in $BAK_DIR — copy step missing."
    return 1
  fi

  echo "[OK] File correctly moved to Documents and copied to Backup."
  return 0
}

# ===== Infra =====
TASKS=(Q1 Q2 Q3 Q4)
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
  rm -rf ~/trainer/files
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
