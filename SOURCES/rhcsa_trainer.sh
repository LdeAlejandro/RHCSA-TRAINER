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

# ===== Resolve correct HOME =====
resolve_home() {
  if [[ $EUID -eq 0 && -n "${SUDO_USER-}" ]]; then
    # Ex.: chamou com sudo; usa HOME do usuário original
    eval echo "~${SUDO_USER}"
  else
    echo "$HOME"
  fi
}

# ===== Start monitored shell (robust) =====
start_monitor() {
  RHCSA_SHM_DIR="${RHCSA_SHM_DIR:-/dev/shm/rhcsa-trainer}"
   echo "Creating directories and files for exercises..."
  mkdir -p "$RHCSA_SHM_DIR"

  sudo mkdir -p /var/tmp/chmod_lab && sudo touch /var/tmp/chmod_lab/{public.log,script.sh,secret.txt,document.txt,private.key,readme.md,hidden.conf}


  # 1) GARANTA as pastas do trainer primeiro, e no HOME correto:
  TRAINER_HOME="$(resolve_home)"
  mkdir -p "$TRAINER_HOME/trainer/Documents" \
           "$TRAINER_HOME/trainer/DocumentBackup" \
           "$TRAINER_HOME/trainer/files"
  tee "$TRAINER_HOME/trainer/files/move_me.txt" > /dev/null <<'EOF'
file and content created: move me to document and copy me to backup
EOF

  # 2) Só depois faça operações privilegiadas:
  sudo mkdir -p /hardfiles
  echo "hard file content" | sudo tee -a /hardfiles/file_data >/dev/null

  sudo mkdir -p /etc/httpd/conf
  sudo touch /etc/httpd/conf/httpd.conf
  # Se falhar por sudo/senha, não derruba o script:
  sudo tee /etc/httpd/conf/httpd.conf > /dev/null <<'EOF' || echo "[WARN] Could not write httpd.conf; continuing."
# =============================
# Basic Apache Configuration
# =============================
Listen 80
ServerName localhost
DocumentRoot "/var/www/html"
<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
ErrorLog "/var/log/httpd/error_log"
CustomLog "/var/log/httpd/access_log" combined
TypesConfig /etc/mime.types
IncludeOptional conf.d/*.conf
ServerAdmin admin@example.com
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
EOF

  sudo touch /root/web.txt

  # ... (restante do seu código igual)
  local LOG="$RHCSA_SHM_DIR/cmd.log"
  local RCFILE="$RHCSA_SHM_DIR/mon.rc"
  : > "$LOG"

  cat >"$RCFILE" <<EOFRC
# RHCSA trainer rcfile
echo "[rhcsa] monitored shell active"
LOG_FILE="$LOG"
trap 'printf "%s\n" "\$BASH_COMMAND" >> "\$LOG_FILE"' DEBUG
PS1="[RHCSA] \u@\h:\w\$ "
EOFRC

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
Q4_DESC="Move the file from the /trainer/files directory to the Documents directory, then copy it to the DocumentBackup directory — all located inside the user’s home directory."

check_Q4() {
  
  local TRAINER_HOME="$(resolve_home)"
  local SRC_DIR="$TRAINER_HOME/trainer/files"
  local DOC_DIR="$TRAINER_HOME/trainer/Documents"
  local BAK_DIR="$TRAINER_HOME/trainer/DocumentBackup"
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

# ===== Exercise Q5 =====
Q5_DESC="Find the string 'Listen' in /etc/httpd/conf/httpd.conf and save the output to /root/web.txt"

check_Q5() {
  local CONF_FILE="/etc/httpd/conf/httpd.conf"
  local OUTPUT_FILE="/root/web.txt"

  # 0) Ensure the source file actually has 'Listen'
  if ! grep -q "Listen" "$CONF_FILE" 2>/dev/null; then
    echo "❌ [FAIL] '$CONF_FILE' does not contain 'Listen' (did you create/populate it?)."
    return 1
  fi

  # 1) Does /root/web.txt exist? (need sudo to see inside /root)
  if ! sudo -n test -f "$OUTPUT_FILE" 2>/dev/null; then
    echo "❌ [FAIL] $OUTPUT_FILE not found. Hint: use:"
    echo "  sudo sh -c 'grep \"Listen\" \"$CONF_FILE\" > \"$OUTPUT_FILE\"'"
    return 1
  fi

  # 2) Does /root/web.txt actually contain 'Listen'?
  if sudo -n grep -q "Listen" "$OUTPUT_FILE" 2>/dev/null; then
    echo "✅ [OK] Correct — 'Listen' lines saved to $OUTPUT_FILE."
    return 0
  else
    echo "❌ [FAIL] $OUTPUT_FILE exists but does not contain 'Listen'."
    echo "Hint: sudo sh -c 'grep \"Listen\" \"$CONF_FILE\" > \"$OUTPUT_FILE\"'"
    return 1
  fi
}

# ===== Exercise Q6 =====
Q6_DESC="Create a gzip-compressed tar archive of /etc named etc_vault.tar.gz in the ~/vaults directory"

check_Q6() {
  local TRAINER_HOME="$(resolve_home)"
  local DEST_DIR="$TRAINER_HOME/vaults"
  local TAR_FILE="$DEST_DIR/etc_vault.tar.gz"

  # 1. Check if the directory exists
  if [[ ! -d "$DEST_DIR" ]]; then
    echo "❌ [FAIL] Directory $DEST_DIR not found — create it with: mkdir ~/vaults"
    return 1
  fi

  # 2. Check if the tar.gz archive exists
  if [[ ! -f "$TAR_FILE" ]]; then
    echo "❌[FAIL] File $TAR_FILE not found — create it with: tar czvf ~/vaults/etc_vault.tar.gz /etc"
    return 1
  fi

  # 3. Validate that it's gzip-compressed
  if file "$TAR_FILE" | grep -q "gzip compressed data"; then
    echo "✅ Q6 Correct — $TAR_FILE is a valid gzip-compressed tar archive."
    return 0
  else
    echo "❌ [FAIL] $TAR_FILE exists but is not a gzip-compressed archive."
    return 1
  fi
}

# ===== Exercise Q7 =====
Q7_DESC="File Links - Create a file file_a in shorts directory and a soft link file_b pointing to file_a"

check_Q7() {
  # 1. Check if directory exists
  if [ ! -d /shorts ]; then
    echo "❌ /shorts directory missing."
    return 1
  fi

  # 2. Check if file_a exists
  if [ ! -f /shorts/file_a ]; then
    echo "❌ /shorts/file_a not found."
    return 1
  fi

  # 3. Check if file_b is a symlink pointing to file_a (absolute path only)
  if [ -h /file_b ]; then
    target=$(readlink /file_b)
    if [ "$target" = "/shorts/file_a" ]; then
      echo "✅ Q7 passed: /file_b correctly links to /shorts/file_a."
      return 0
    else
      echo "❌ /file_b points to '$target' instead of '/shorts/file_a'."
      return 1
    fi
  else
    echo "❌ /file_b is missing or not a symlink."
    return 1
  fi
}

# ===== Exercise Q8 =====
Q8_DESC="File Links - Create a hard link of the file in hardfiles directory to file_c"

check_Q8() {
  # 3. Check hardlink
  if [ -f /file_c ] && [ "$(stat -c %h /hardfiles/file_data)" -eq "$(stat -c %h /file_c)" ]; then
    echo "✅ Q8 passed: /file_c is a hard link to /hardfiles/file_data."
    return 0
  else
    echo "❌ /file_c is missing or not a hard link to /hardfiles/file_data."
    return 1
  fi
  
}

# ===== Exercise Q9 =====
Q9_DESC="Find files in /usr that are greater than 3MB but < 10MB and copy them to /bigfiles directory."

check_Q9() {
  # 1. Check if /bigfiles directory exists
  if [ ! -d /bigfiles ]; then
    echo "❌ /bigfiles directory missing."
    return 1
  fi

  # 2. Check if files were copied
  if [ "$(ls -A /bigfiles)" ]; then
    echo "✅ Q9 passed: Files copied to /bigfiles."
    return 0
  else
    echo "❌ Q9 failed: No files found matching criteria."
    return 1
  fi
}

# ===== Exercise Q10 =====
Q10_DESC="Find files in /etc modified more than 120 days ago and copy them to /var/tmp/twenty/"

check_Q10() {
  # 1. Check if files were copied
  if [ "$(ls -A /var/tmp/twenty/)" ]; then
    echo "✅ Q10 passed: Files copied to /var/tmp/twenty/."
    return 0
  else
    echo "❌ Q10 failed: No files found matching criteria."
    return 1
  fi
}

# ===== Exercise Q11 =====
Q11_DESC="Find all files owned by user rhel and copy them to /var/tmp/rhel-files."

check_Q11() {
  # 1. Check if files were copied
  if [ "$(ls -A /var/tmp/rhel-files/)" ]; then
    echo "✅ Q11 passed: Files copied to /var/tmp/rhel-files/."
    return 0
  else
    echo "❌ Q11 failed: No files found matching criteria."
    return 1
  fi
}

# ===== Exercise Q12 =====
Q12_DESC="Find a file named 'httpd.conf' and save the absolute paths to /root/httpd-paths.txt."


check_Q12() {
  if sudo -n test -f /root/httpd-paths.txt 2>/dev/null; then
    if sudo -n grep -q '^/' /root/httpd-paths.txt 2>/dev/null; then
      echo "✅ Q12 passed: File contains absolute paths."
      return 0
    else
      echo "❌ Q12 failed: File exists but does not contain absolute paths."
      return 1
    fi
  else
    echo "❌ Q12 failed: /root/httpd-paths.txt not found."
    return 1
  fi
}

# ===== Exercise Q12 =====
Q13_DESC="Copy the contents of /etc/fstab to /var/tmp, Set the file ownership to root, Ensure no execute permissions for anyone"
check_Q13() {
  if sudo -n test -f /var/tmp/fstab 2>/dev/null; then
    if sudo -n stat -c '%U' /var/tmp/fstab 2>/dev/null | grep -q '^root$' && \
       sudo -n stat -c '%G' /var/tmp/fstab 2>/dev/null | grep -q '^root$' && \
       ! sudo -n test -x /var/tmp/fstab 2>/dev/null; then
      echo "✅ Q13 passed: Ownership and permissions are correct."
      return 0
    else
      echo "❌ Q13 failed: Ownership or permissions are incorrect."
      return 1
    fi
  else
    echo "❌ Q13 failed: /var/tmp/fstab not found."
    return 1
  fi
}

# ===== Exercise Q14 =====
Q14_DESC="Give full permissions to everyone on /var/tmp/chmod_lab/public.log and set owner:group to root:root"
check_Q14() {
  if sudo -n test -f /var/tmp/chmod_lab/public.log 2>/dev/null; then
    if sudo -n stat -c '%a' /var/tmp/chmod_lab/public.log | grep -q '^777$' && \
       sudo -n stat -c '%U' /var/tmp/chmod_lab/public.log | grep -q '^root$' && \
       sudo -n stat -c '%G' /var/tmp/chmod_lab/public.log | grep -q '^root$'; then
      echo "✅ Q14 passed: Permissions and ownership correct."
      return 0
    else
      echo "❌ Q14 failed: Incorrect permissions or ownership."
      return 1
    fi
  else
    echo "❌ Q14 failed: File not found."
    return 1
  fi
}

# ===== Exercise Q15 =====
Q15_DESC="Allow the owner to read/write/execute, while others can only read and execute on /var/tmp/chmod_lab/script.sh. Set owner:group to devops:devs."
check_Q15() {
  if sudo -n test -f /var/tmp/chmod_lab/script.sh 2>/dev/null; then
    if sudo -n stat -c '%a' /var/tmp/chmod_lab/script.sh | grep -q '^755$' && \
       sudo -n stat -c '%U' /var/tmp/chmod_lab/script.sh | grep -q '^devops$' && \
       sudo -n stat -c '%G' /var/tmp/chmod_lab/script.sh | grep -q '^devs$'; then
      echo "✅ Q15 passed: Permissions and ownership correct."
      return 0
    else
      echo "❌ Q15 failed: Incorrect permissions or ownership."
      return 1
    fi
  else
    echo "❌ Q15 failed: File not found."
    return 1
  fi
}

# ===== Exercise Q16 =====
Q16_DESC="Allow only the owner to read, write, and execute on /var/tmp/chmod_lab/secret.txt. Set owner:group to admin:admins."
check_Q16() {
  if sudo -n test -f /var/tmp/chmod_lab/secret.txt 2>/dev/null; then
    if sudo -n stat -c '%a' /var/tmp/chmod_lab/secret.txt | grep -q '^700$' && \
       sudo -n stat -c '%U' /var/tmp/chmod_lab/secret.txt | grep -q '^admin$' && \
       sudo -n stat -c '%G' /var/tmp/chmod_lab/secret.txt | grep -q '^admins$'; then
      echo "✅ Q16 passed: Permissions and ownership correct."
      return 0
    else
      echo "❌ Q16 failed: Incorrect permissions or ownership."
      return 1
    fi
  else
    echo "❌ Q16 failed: File not found."
    return 1
  fi
}

# ===== Exercise Q17 =====
Q17_DESC="Allow the owner to read and write, while others can only read /var/tmp/chmod_lab/document.txt. Set owner:group to student:students."
check_Q17() {
  if sudo -n test -f /var/tmp/chmod_lab/document.txt 2>/dev/null; then
    if sudo -n stat -c '%a' /var/tmp/chmod_lab/document.txt | grep -q '^644$' && \
       sudo -n stat -c '%U' /var/tmp/chmod_lab/document.txt | grep -q '^student$' && \
       sudo -n stat -c '%G' /var/tmp/chmod_lab/document.txt | grep -q '^students$'; then
      echo "✅ Q17 passed: Permissions and ownership correct."
      return 0
    else
      echo "❌ Q17 failed: Incorrect permissions or ownership."
      return 1
    fi
  else
    echo "❌ Q17 failed: File not found."
    return 1
  fi
}

# ===== Exercise Q18 =====
Q18_DESC="Allow only the owner to read and write /var/tmp/chmod_lab/private.key. No one else should have access. Set owner:group to tester:qa."
check_Q18() {
  if sudo -n test -f /var/tmp/chmod_lab/private.key 2>/dev/null; then
    if sudo -n stat -c '%a' /var/tmp/chmod_lab/private.key | grep -q '^600$' && \
       sudo -n stat -c '%U' /var/tmp/chmod_lab/private.key | grep -q '^tester$' && \
       sudo -n stat -c '%G' /var/tmp/chmod_lab/private.key | grep -q '^qa$'; then
      echo "✅ Q18 passed: Permissions and ownership correct."
      return 0
    else
      echo "❌ Q18 failed: Incorrect permissions or ownership."
      return 1
    fi
  else
    echo "❌ Q18 failed: File not found."
    return 1
  fi
}

# ===== Exercise Q19 =====
Q19_DESC="Allow only the owner to read /var/tmp/chmod_lab/readme.md. Everyone else should have no access. Set owner:group to analyst:finance."
check_Q19() {
  if sudo -n test -f /var/tmp/chmod_lab/readme.md 2>/dev/null; then
    if sudo -n stat -c '%a' /var/tmp/chmod_lab/readme.md | grep -q '^400$' && \
       sudo -n stat -c '%U' /var/tmp/chmod_lab/readme.md | grep -q '^analyst$' && \
       sudo -n stat -c '%G' /var/tmp/chmod_lab/readme.md | grep -q '^finance$'; then
      echo "✅ Q19 passed: Permissions and ownership correct."
      return 0
    else
      echo "❌ Q19 failed: Incorrect permissions or ownership."
      return 1
    fi
  else
    echo "❌ Q19 failed: File not found."
    return 1
  fi
}

# ===== Exercise Q20  =====
Q20_DESC="Remove all permissions from /var/tmp/chmod_lab/hidden.conf. No one should be able to read, write, or execute it. Set owner:group to backup:storage."
check_Q20() {
  local f="/var/tmp/chmod_lab/hidden.conf"
  if sudo -n test -f "$f" 2>/dev/null; then
    # Accept 0 or 000; also verify owner/group
    if sudo -n stat -c '%a' "$f" 2>/dev/null | grep -Eq '^(0|000)$' && \
       sudo -n stat -c '%U' "$f" 2>/dev/null | grep -q '^backup$' && \
       sudo -n stat -c '%G' "$f" 2>/dev/null | grep -q '^storage$'; then
      echo "✅ Q20 passed: Ownership and permissions are correct."
      return 0
    else
      echo "❌ Q20 failed: Ownership or permissions are incorrect."
      echo "    Debug -> $(sudo -n stat -c 'perm=%a owner=%U group=%G' "$f" 2>/dev/null)"
      return 1
    fi
  else
    echo "❌ Q20 failed: $f not found."
    return 1
  fi
}

# ===== Exercise Q21 =====
Q21_DESC="Create a shell script /root/find-files.sh that finds files in /usr between 30KB and 50KB and saves results to /root/sized_files.txt."
check_Q21() {
  local script="/root/find-files.sh"
  local output="/root/sized_files.txt"

  # Check if the script exists and is executable
  if sudo -n test -f "$script" 2>/dev/null; then
    if ! sudo -n test -x "$script" 2>/dev/null; then
      echo "❌ Q21 failed: Script exists but is not executable."
      return 1
    fi

    # Verify that it contains the expected 'find' command
    if ! sudo -n grep -Eq 'find[[:space:]]+/usr[[:space:]]+-type[[:space:]]+f[[:space:]]+-size[[:space:]]+\+30k[[:space:]]+-size[[:space:]]+-50k' "$script"; then
      echo "❌ Q21 failed: Script content is incorrect or missing find command."
      return 1
    fi
  else
    echo "❌ Q21 failed: Script $script not found."
    return 1
  fi

  # Run the script to ensure it generates output correctly
  sudo -n bash "$script" 2>/dev/null

  if sudo -n test -f "$output" 2>/dev/null; then
    # Ensure the file isn't empty
    if [[ $(sudo -n wc -l < "$output") -gt 0 ]]; then
      echo "✅ Q21 passed: Script created and executed correctly, output generated."
      return 0
    else
      echo "❌ Q21 failed: Output file exists but is empty."
      return 1
    fi
  else
    echo "❌ Q21 failed: Output file not created."
    return 1
  fi
}

# ===== Infra =====
TASKS=(Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8 Q9 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21)
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
  local TRAINER_HOME
  TRAINER_HOME="$(resolve_home)"
  [[ -n "$TRAINER_HOME" ]] || TRAINER_HOME="${HOME:-/root}"

  for id in "${TASKS[@]}"; do STATUS[$id]="${YELLOW}PENDING${RESET}"; done
  rm -f hello.txt
  rm -rf "${TRAINER_HOME}/.ssh/"* 2>/dev/null || true
  rm -f  "$RHCSA_SHM_DIR/cmd.log" 2>/dev/null || true
  rm -rf "${TRAINER_HOME}/trainer" 2>/dev/null || true
  rm -rf "${TRAINER_HOME}/vaults"        2>/dev/null || true
  rm -rf /hardfiles /shorts 2>/dev/null || true
  rm -f  /file_b /file_c 2>/dev/null || true
  sudo rm -rf /bigfiles 2>/dev/null || true
  sudo rm -rf /var/tmp/twenty/ 2>/dev/null || true
  sudo rm -rf /var/tmp/rhel-files 2>/dev/null || true
  sudo rm -rf /var/tmp/fstab 2>/dev/null || true
  sudo rm -rf /root/httpd-paths.txt 2>/dev/null || true
  sudo rm -f -- /root/web.txt 2>/dev/null || true
  sudo rm -rf /var/tmp/chmod_lab 2>/dev/null || true

  #delete Q14 to Q20 user and groups and files

  # Users: devops, admin, student, tester, analyst, backup
for u in devops admin student tester analyst backup; do
  if getent passwd "$u" >/dev/null; then
    sudo pkill -u "$u" 2>/dev/null || true
    sudo userdel -r "$u"
    echo "Deleted user: $u"
  else
    echo "User not found: $u"
  fi
done

# Groups: devs, admins, students, qa, finance, storage
for g in devs admins students qa finance storage; do
  if getent group "$g" >/dev/null; then
    sudo groupdel "$g"
    echo "Deleted group: $g"
  else
    echo "Group not found: $g"
  fi
done

sudo rm -rf /var/tmp/chmod_lab 2>/dev/null || true
#
  sudo rm -f /root/find-files.sh 2>/dev/null || true
  sudo rm -f /root/sized_files.txt 2>/dev/null || true


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
  reset) reset_all;  ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
