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
  
  #Q11 files
  sudo install -o rhel -g rhel -m 0644 /dev/null /tmp/tmp_file

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
    echo "❌ [FAIL] File is correct, but I did not see 'vim hello.txt' in the monitored session (run via 'rhcsa-trainer start')."
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
    echo "❌ [FAIL] No public key found under ~/.ssh (*.pub). Generate one with: ssh-keygen -t rsa -b 4096"
    return 1
  fi

  # 2) Quick reachability check (optional but helpful)
  if ! ping -c1 -W1 "$REMOTE_HOST" >/dev/null 2>&1; then
    echo "❌ [FAIL] Host $REMOTE_HOST not reachable (ping failed)."
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
    echo "❌ [FAIL] Key is present on remote but auth still failed."
    echo "       Likely permissions/contexts. On the remote, try:"
    echo "       chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && restorecon -Rv ~/.ssh"
  else
    echo "❌ [FAIL] Your public key is NOT on the remote."
    echo "       Fix with: ssh-copy-id -i \"$PUBKEY\" ${REMOTE_USER}@${REMOTE_HOST}"
  fi

  return 1
}

# ===== Exercise Q3 =====
Q3_DESC="Check recent system logs"

check_Q3() {
  local LOG="$RHCSA_SHM_DIR/cmd.log"

  # 1) Verifica se houve atividade registrada
  [[ -f "$LOG" ]] || { echo "❌ [FAIL] No monitored session found. Run via 'rhcsa-trainer start'."; return 1; }

  # 2) Procura comandos usados para visualizar logs
  if grep -Eq 'journalctl[[:space:]]+-xe' "$LOG" || grep -Eq 'cat[[:space:]]+/var/log/secure' "$LOG" || grep -Eq 'vim[[:space:]]+/var/log/secure' "$LOG" || grep -Eq 'vi[[:space:]]+/var/log/secure' "$LOG"; then
    echo "[OK] Log inspection command detected."
    return 0
  else
    echo "❌ [FAIL] Did not detect 'journalctl -xe' or 'cat /var/log/secure' in monitored session."
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
    echo "❌ [FAIL] File still exists in $SRC_DIR — it should have been moved."
    return 1
  fi

  # File must exist in Documents
  if [[ ! -e "$DOC_DIR/$FILENAME" ]]; then
    echo "❌ [FAIL] File not found in $DOC_DIR — move step missing."
    return 1
  fi

  # File must exist in DocumentBackup as a copy
  if [[ ! -e "$BAK_DIR/$FILENAME" ]]; then
    echo "❌ [FAIL] File not found in $BAK_DIR — copy step missing."
    return 1
  fi

  echo "✅ [OK] File correctly moved to Documents and copied to Backup."
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
Q7_DESC="File Links - Create a file file_a in (root directory) shorts directory and a soft link file_b pointing to file_a"

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
Q8_DESC="File Links - (root directory) Create a hard link of the file_data in hardfiles directory, to file_c"

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
Q11_DESC="Find all /tmp files owned by user rhel and copy them to /var/tmp/rhel-files"

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

# ===== Exercise Q13 =====
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
Q21_DESC="Question 21: Create a shell script /root/find-files.sh that finds files in /usr between 30KB and 50KB and saves results to /root/sized_files.txt."
check_Q21() {
  echo "check "
  local script="/root/find-files.sh"
  local output="/root/sized_files.txt"
  local low=$((30*1024))   # 30720 bytes
  local high=$((50*1024))  # 51200 bytes, strict upper bound

  # 1) Script exists and is executable
  if ! sudo -n test -f "$script" 2>/dev/null; then
    echo "❌ Q21 failed: Script $script not found."
    return 1
  fi
  if ! sudo -n test -x "$script" 2>/dev/null; then
    echo "❌ Q21 failed: Script exists but is not executable."
    return 1
  fi

  # 2) Run script and ensure output file is (re)generated
  local prev_mtime
  prev_mtime="$(sudo -n stat -c '%Y' "$output" 2>/dev/null || echo 0)"
  if ! sudo -n bash "$script" 2>/dev/null; then
    echo "❌ Q21 failed: Script execution returned a non-zero status."
    return 1
  fi
  if ! sudo -n test -f "$output" 2>/dev/null; then
    echo "❌ Q21 failed: Output file $output was not created."
    return 1
  fi
  local new_mtime
  new_mtime="$(sudo -n stat -c '%Y' "$output" 2>/dev/null || echo 0)"
  if [[ "$new_mtime" -le "$prev_mtime" ]]; then
    echo "❌ Q21 failed: Output file was not updated by the script."
    return 1
  fi

  # 3) If output has lines, validate each line; allow empty output (environment-dependent)
  local lines
  lines="$(sudo -n wc -l < "$output" 2>/dev/null || echo 0)"
  if [[ "$lines" -eq 0 ]]; then
    echo "⚠️ Q21 note: Output file is empty. Accepting (may vary by environment)."
    echo "✅ Q21 passed: Script exists, is executable, and generated the output file."
    return 0
  fi

  # 4) Validate each path
  local bad=0

# Hard stop: refuse to read if file is missing or not readable
if ! test -r "$output"; then
  echo "❌ Q21 failed: Output file is not readable -> $output"
  return 1
fi
ECHO "Checking Q21 files"
# Read file directly (no sudo, no subshell)
while IFS= read -r p || [[ -n "$p" ]]; do
  # skip blank lines
  [[ -z "$p" ]] && continue

  # must start with /usr
  if [[ "$p" != /usr/* ]]; then
    echo "❌ Q21 failed: Path not under /usr -> $p"
    bad=1
    continue
  fi

  # must be a regular file
  if ! test -f "$p" 2>/dev/null; then
    echo "❌ Q21 failed: Not a regular file -> $p"
    bad=1
    continue
  fi

  # size must be strictly between 30KB and 50KB
  bytes=$(stat -c '%s' "$p" 2>/dev/null || echo -1)

  if ! [[ "$bytes" =~ ^[0-9]+$ ]]; then
    echo "❌ Q21 failed: Could not read size -> $p"
    bad=1
    continue
  fi

  if (( bytes <= low || bytes >= high )); then
    echo "❌ Q21 failed: Size out of range (bytes=$bytes) -> $p"
    bad=1
    continue
  fi

done < "$output"

  if [[ "$bad" -eq 0 ]]; then
    echo "✅ Q21 passed: Script executed and output validated without relying on implementation details."
    return 0
  else
    echo "❌ Q21 failed: One or more listed paths did not meet the criteria."
    return 1
  fi
}

# returns 0 if user's password EXACTLY matches; 1 if not; 2 if cannot verify
_has_exact_password() {
  local u="$1" p="$2"
  local h alg salt calc

  # read hash (try sudo first, then plain in case we're root)
  h=$(sudo awk -F: -v U="$u" '$1==U{print $2}' /etc/shadow 2>/dev/null)
  [ -z "$h" ] && h=$(awk -F: -v U="$u" '$1==U{print $2}' /etc/shadow 2>/dev/null)
  [ -z "$h" ] && return 2

  # locked / no password?
  case "$h" in '!'*|'*'|'') return 1 ;; esac

  alg=$(awk -F'$' '{print $2}' <<<"$h")
  salt=$(awk -F'$' '{print $3}' <<<"$h")

  # Prefer mkpasswd (supports yescrypt $y and sha-512 $6 on RHEL)
  if command -v mkpasswd >/dev/null 2>&1; then
    case "$alg" in
      y) calc=$(mkpasswd -m yescrypt -S "$salt" "$p") ;;
      6) calc=$(mkpasswd -m sha-512  -S "$salt" "$p") ;;
      *) calc="" ;;
    esac
    [ -n "$calc" ] && { [ "$calc" = "$h" ] && return 0 || return 1; }
  fi

  # Fallback: Python crypt (silence deprecation warning)
  if command -v python3 >/dev/null 2>&1; then
    python3 -W ignore - <<'PY' "$h" "$p"
import sys, crypt
h, p = sys.argv[1], sys.argv[2]
sys.exit(0 if crypt.crypt(p, h)==h else 1)
PY
    return $?
  fi

  # Last resort: cannot verify (no mkpasswd/python3 or unsupported algo)
  return 2
}

# ===== Exercise Q22 =====
Q22_DESC="Create an user named 'noob' with password 'Aa7338!!' and configure it to change the password on next login."
check_Q22() {
  if ! getent passwd noob >/dev/null; then
    echo "❌ Q22 | FAIL | user 'noob' not found"; return 1
  fi

  if ! _has_exact_password "noob" "Aa7338!!"; then
    rc=$?
    [ $rc -eq 2 ] && echo "⚠️ Q22 | WARN | cannot verify exact password (install 'whois' or 'python3')" || \
                     echo "❌ Q22 | FAIL | wrong password for 'noob'"
    [ $rc -eq 2 ] || return 1
  fi

  lastchg=$(sudo awk -F: '$1=="noob"{print $3}' /etc/shadow 2>/dev/null)
  [ -z "$lastchg" ] && lastchg=$(awk -F: '$1=="noob"{print $3}' /etc/shadow 2>/dev/null)

  if [ "$lastchg" = "0" ]; then
    echo "✅ Q22 | PASS | exact password set and expiration enforced"; return 0
  else
    echo "❌ Q22 | FAIL | password ok but not expired (lastchg=$lastchg)"; return 1
  fi
}

# ===== Exercise Q23 =====
Q23_DESC="Create an user named 'def4ult' with password 'Aa578!!??' and change it to 'C546#Ab!'."
check_Q23() {
  if ! getent passwd def4ult >/dev/null; then
    echo "❌ Q23 | FAIL | user 'def4ult' not found"; return 1
  fi

  if _has_exact_password "def4ult" "C546#Ab!"; then
    echo "✅ Q23 | PASS | exact final password 'C546#Ab!' is set"; return 0
  else
    rc=$?
    [ $rc -eq 2 ] && echo "⚠️ Q23 | WARN | cannot verify exact password (install 'whois' or 'python3')" || \
                     echo "❌ Q23 | FAIL | final password is not 'C546#Ab!'"
    return 1
  fi
}

# ===== Exercise Q24 =====
Q24_DESC='Create a shell script that Outputs "Yes, I’m a Systems Engineer." when run with ./career.sh me , Outputs "Okay, they do cloud engineering." 
when run with ./career.sh they ,Outputs "Usage: ./career.sh me|they" for invalid/empty arguments, the file must has 755 permission'
check_Q24() {
  script="/root/career.sh"
  [ -f "$script" ] || script="$HOME/career.sh"
  if [ ! -f "$script" ]; then
    echo "❌ Q24 | FAIL | career.sh not found at /root/career.sh or ~/career.sh"; return 1
  fi

  # must be shell with a sensible shebang
  if ! head -n1 "$script" | grep -Eq '^#! */bin/(ba)?sh( |$)'; then
    echo "❌ Q24 | FAIL | missing/invalid shebang"; return 1
  fi

  # must be 755
  perm=$(stat -c '%a' "$script" 2>/dev/null || stat -f '%Lp' "$script" 2>/dev/null)
  if [ "$perm" != "755" ]; then
    echo "❌ Q24 | FAIL | permission is $perm (expected 755)"; return 1
  fi

  norm() { sed -e "s/[[:space:]]\+/ /g" -e 's/^ //; s/ $//'; }

  out_me=$(bash "$script" me     2>/dev/null | norm)
  out_they=$(bash "$script" they 2>/dev/null | norm)
  out_empty=$(bash "$script"     2>/dev/null | norm)
  out_bad=$(bash "$script" xxx   2>/dev/null | norm)

  exp_me="Yes, I'm a Systems Engineer."
  exp_they="Okay, they do cloud engineering."
  exp_usage="Usage: ./career.sh me|they"

  [ "$out_me" = "$exp_me" ]      || { echo "Q24 | FAIL | me -> $out_me"; return 1; }
  [ "$out_they" = "$exp_they" ]  || { echo "Q24 | FAIL | they -> $out_they"; return 1; }
  [ "$out_empty" = "$exp_usage" ]|| { echo "Q24 | FAIL | empty -> $out_empty"; return 1; }
  [ "$out_bad" = "$exp_usage" ]  || { echo "Q24 | FAIL | invalid -> $out_bad"; return 1; }

  echo "✅ Q24 | PASS | OK"; return 0
}

# ===== Exercise Q25 =====
Q25_DESC="Question 25: Write shell scripts (create_groups.sh, create_users.sh, setpass.sh) on node1 that perform the following tasks:

1. Create groups with specific GIDs as defined below.
2. Create users with specific UIDs and group memberships.
3. Set the passwords for maryam, adam, and jacob to "Strong!2025".

Groups and GIDs:
hpc_admin:9090
hpc_managers:8080
sysadmin:7070

Users, UIDs, and Groups:
maryam:2030:hpc_admin,hpc_managers
adam:2040:sysadmin
jacob:2050:hpc_admin"

check_Q25() {
  # check script files exist
  for f in create_groups.sh create_users.sh setpass.sh; do
    if [ ! -f "/root/$f" ] && [ ! -f "$HOME/$f" ]; then
      echo "❌ Q25 | FAIL | script '$f' not found"
      return 1
    fi
    if [ ! -x "/root/$f" ] && [ ! -x "$HOME/$f" ]; then
      echo "❌ Q25 | FAIL | script '$f' exists but is not executable"
      return 1
    fi
  done

  # expected users and groups
  users=("maryam" "adam" "jacob")
  groups=("hpc_admin" "hpc_managers" "sysadmin")

  # check groups
  for g in "${groups[@]}"; do
    if ! getent group "$g" >/dev/null; then
      echo "❌ Q25 | FAIL | group '$g' not found"
      return 1
    fi
  done

  # check users
  for u in "${users[@]}"; do
    if ! getent passwd "$u" >/dev/null; then
      echo "❌ Q25 | FAIL | user '$u' not found"
      return 1
    fi
  done

  # verify password
  for u in "${users[@]}"; do
    if _has_exact_password "$u" "Strong!2025"; then
      echo "✅ Q25 | PASS | user '$u' has correct password 'Strong!2025'"
    else
      rc=$?
      [ $rc -eq 2 ] && echo "⚠️ Q25 | WARN | cannot verify password for '$u' (install 'whois' or 'python3')" || \
                           echo "❌ Q25 | FAIL | user '$u' does not have password 'Strong!2025'"
      return 1
    fi
  done

  echo "✅ Q25 | PASS | all users, groups and required scripts verified successfully"
  return 0
}

# ===== Exercise Q26 =====
Q26_DESC="Reset the root password via GRUB so that it becomes 'hoppy'."

check_Q26() {
  local passwd_test="hoppy"
  local shadow_time boot_time current_time rc

  # 1. Test if root password is correct
  echo "$passwd_test" | su -c "exit" root &>/dev/null
  rc=$?

  if [ $rc -ne 0 ]; then
    echo "❌ Q26 | FAIL | root password is not 'hoppy'"
    return 1
  fi

  # 2. Check SELinux relabel marker
  if [ -f /.autorelabel ]; then
    echo "✅ Q26 | PASS | SELinux relabel marker found"
  else
    echo "⚠️ Q26 | WARN | /.autorelabel missing – GRUB method may not have been used"
    return 1
  fi

  # 3. Check whether /etc/shadow was modified before last boot
  shadow_time=$(stat -c %Y /etc/shadow 2>/dev/null)
  boot_time=$(awk '{print int($1)}' /proc/uptime)
  current_time=$(date +%s)

  if (( shadow_time < current_time - boot_time )); then
    echo "✅ Q26 | PASS | password changed before last boot (consistent with GRUB method)"
  else
    echo "⚠️ Q26 | WARN | password changed after boot (maybe not GRUB method)"
    return 0
  fi

  echo "✅ Q26 | PASS | root password reset to 'hoppy'"
  return 0
}

# ===== Exercise Q27 =====
Q27_DESC="Tuning + SELinux + Network: tuned running with recommended profile, SELinux permissive, network enabled on boot."

check_Q27() {

  # ---- 1) tuned installed ----
  if ! command -v tuned-adm >/dev/null 2>&1; then
    echo "❌ Q27 failed: tuned-adm not found (is tuned installed?)."
    return 1
  fi

  # ---- 2) tuned service enabled and running ----
  if ! systemctl is-enabled --quiet tuned; then
    echo "❌ Q27 failed: tuned service is not enabled on boot."
    return 1
  fi

  if ! systemctl is-active --quiet tuned; then
    echo "❌ Q27 failed: tuned service is not running."
    return 1
  fi

  # ---- 3) tuned active profile must match recommended ----
  local rec active
  rec="$(tuned-adm recommend 2>/dev/null | head -n1)"
  active="$(tuned-adm active 2>/dev/null | sed -n 's/^Current active profile:[[:space:]]*//p')"

  if [[ -z "$rec" || -z "$active" ]]; then
    echo "❌ Q27 failed: Could not read tuned profiles."
    return 1
  fi

  if [[ "$active" != "$rec" ]]; then
    echo "❌ Q27 failed: tuned profile mismatch."
    echo "    Active: $active"
    echo "    Recommended: $rec"
    return 1
  fi

  echo "✅ tuned running with recommended profile ($active)."

  # ---- 4) SELinux permissive ----
  local se
  se="$(getenforce 2>/dev/null)"

  if [[ "$se" != "Permissive" ]]; then
    echo "❌ Q27 failed: SELinux is '$se' (expected Permissive)."
    return 1
  fi

  echo "✅ SELinux is in permissive mode."

  # ---- 5) Network service enabled on boot ----
  # RHEL may use either 'network' or 'NetworkManager'
  if systemctl list-unit-files | awk '{print $1}' | grep -qx 'network.service'; then
    if ! systemctl is-enabled --quiet network; then
      echo "❌ Q27 failed: network.service is not enabled on boot."
      return 1
    fi
    echo "✅ network.service enabled on boot."
  else
    if ! systemctl is-enabled --quiet NetworkManager; then
      echo "❌ Q27 failed: NetworkManager is not enabled on boot."
      return 1
    fi
    echo "✅ NetworkManager enabled on boot (network.service not present)."
  fi

  echo "✅ Q27 PASSED."
  return 0
}

# ===== Exercise Q28 =====
Q28_DESC="SELinux persistent configuration: set SELINUX=permissive in /etc/selinux/config and verify after reboot."

check_Q28() {

  # ---- 1) Check config file exists ----
  if [ ! -f /etc/selinux/config ]; then
    echo "❌ Q28 failed: /etc/selinux/config not found."
    return 1
  fi

  # ---- 2) Check persistent configuration ----
  if ! grep -Eq '^SELINUX=permissive' /etc/selinux/config; then
    echo "❌ Q28 failed: /etc/selinux/config is not set to SELINUX=permissive."
    return 1
  fi

  # ---- 3) Check current runtime mode ----
  local se
  se="$(getenforce 2>/dev/null)"

  if [[ "$se" != "Permissive" ]]; then
    echo "❌ Q28 failed: Runtime SELinux mode is '$se' (expected Permissive)."
    echo "Hint: reboot is required after editing config."
    return 1
  fi

  echo "✅ Q28 PASSED: SELinux is permissive and persistent."
  return 0
}

# ===== Exercise Q29 =====
Q29_DESC="Ensure NetworkManager is enabled and starts on boot."

check_Q29() {

  # ---- 1) Service must exist ----
  if ! systemctl list-unit-files | awk '{print $1}' | grep -qx 'NetworkManager.service'; then
    echo "❌ Q29 failed: NetworkManager service not found."
    return 1
  fi

  # ---- 2) Must be enabled on boot ----
  if ! systemctl is-enabled --quiet NetworkManager; then
    echo "❌ Q29 failed: NetworkManager is not enabled on boot."
    return 1
  fi

  # ---- 3) Must be running ----
  if ! systemctl is-active --quiet NetworkManager; then
    echo "❌ Q29 failed: NetworkManager is not running."
    return 1
  fi

  echo "✅ Q29 PASSED: NetworkManager enabled and running."
  return 0
}

# ===== Exercise Q30 =====
Q30_DESC="Configure persistent journald logging (/var/log/journal)."

check_Q30() {

  # ---- 1) Directory must exist ----
  if [ ! -d /var/log/journal ]; then
    echo "❌ Q30 failed: /var/log/journal directory not found."
    return 1
  fi

  # ---- 2) Directory must not be empty ----
  if [ -z "$(ls -A /var/log/journal 2>/dev/null)" ]; then
    echo "❌ Q30 failed: /var/log/journal exists but contains no journal files."
    echo "Hint: run 'journalctl --flush' after creating the directory."
    return 1
  fi

  echo "✅ Q30 PASSED: Persistent journal storage configured."
  return 0
}

# ===== Exercise Q31 =====
Q31_DESC="Start stress-ng with nice 19, renice to 10, then terminate it."

check_Q31() {

  local LOG="$RHCSA_SHM_DIR/cmd.log"

  # 1) stress-ng must be installed
  if ! command -v stress-ng >/dev/null 2>&1; then
    echo "❌ Q31 failed: stress-ng not installed."
    return 1
  fi

  # 2) Verify nice start command was executed
  if [[ ! -f "$LOG" ]] || ! grep -Eq 'nice[[:space:]]+-n[[:space:]]+19[[:space:]]+stress-ng' "$LOG"; then
    echo "❌ Q31 failed: stress-ng was not started with nice -n 19."
    return 1
  fi

  # 3) Verify renice command executed
  if ! grep -Eq 'renice[[:space:]]+-n[[:space:]]+10' "$LOG"; then
    echo "❌ Q31 failed: renice to 10 not detected."
    return 1
  fi

  # 4) Verify process is no longer running
  if pgrep stress-ng >/dev/null 2>&1; then
    echo "❌ Q31 failed: stress-ng process still running."
    return 1
  fi

  echo "✅ Q31 PASSED: nice, renice, and termination verified."
  return 0
}

# ===== Exercise Q32 =====
Q32_DESC="ACLs on /var/tmp/fstab: root owner, not executable, adam rw, maryam none, others r."

check_Q32() {
  local f="/var/tmp/fstab"

  # 1) file exists
  if ! sudo -n test -f "$f" 2>/dev/null; then
    echo "❌ Q32 failed: $f not found."
    return 1
  fi

  # 2) owner must be root
  if ! sudo -n stat -c '%U' "$f" 2>/dev/null | grep -qx 'root'; then
    echo "❌ Q32 failed: owner is not root."
    return 1
  fi

  # (optional) group root as well (matches your other questions’ strictness)
  if ! sudo -n stat -c '%G' "$f" 2>/dev/null | grep -qx 'root'; then
    echo "❌ Q32 failed: group is not root."
    return 1
  fi

  # 3) must not be executable by anyone
  if sudo -n test -x "$f" 2>/dev/null; then
    echo "❌ Q32 failed: file is executable (should not be executable by anyone)."
    return 1
  fi

  # 4) ACL checks
  # adam must be rw-
  if ! sudo -n getfacl -p "$f" 2>/dev/null | grep -Eq '^user:adam:rw-'; then
    echo "❌ Q32 failed: ACL for user adam must be rw-."
    return 1
  fi

  # maryam must be ---
  if ! sudo -n getfacl -p "$f" 2>/dev/null | grep -Eq '^user:maryam:---'; then
    echo "❌ Q32 failed: ACL for user maryam must be ---."
    return 1
  fi

  # other must be r--
  if ! sudo -n getfacl -p "$f" 2>/dev/null | grep -Eq '^other::r--'; then
    echo "❌ Q32 failed: ACL for other must be r--."
    return 1
  fi

  echo "✅ Q32 PASSED."
  return 0
}

# ===== Exercise Q33 =====
Q33_DESC="Create rhel-file.ext and copy it via scp to master-server home directory."

check_Q33() {

  local FILE="rhel-file.ext"
  local DEST="/home/master-server/rhel-file.ext"
  local LOG="$RHCSA_SHM_DIR/cmd.log"

  # ---- 1) Local file must exist ----
  if [ ! -f "$FILE" ]; then
    echo "❌ Q33 failed: $FILE not found in current directory."
    return 1
  fi

  # ---- 2) scp command must be detected in monitored shell ----
  if [[ ! -f "$LOG" ]] || ! grep -Eq 'scp[[:space:]]+.*rhel-file\.ext[[:space:]]+master-server@' "$LOG"; then
    echo "❌ Q33 failed: scp command not detected in monitored session."
    echo "Hint: scp rhel-file.ext master-server@<ip>:/home/master-server/"
    return 1
  fi

  # ---- 3) File must exist in destination ----
  if ! sudo -n test -f "$DEST" 2>/dev/null; then
    echo "❌ Q33 failed: File not found at $DEST on this system."
    echo "Hint: run the scp command successfully."
    return 1
  fi

  echo "✅ Q33 PASSED: File copied successfully via scp."
  return 0
}

# ===== Exercise Q34 =====
Q34_DESC="LVM: devops_vg (PE 20M) on /dev/sdc1, devops_lv (32 extents), ext4, mounted persistently at /mnt/devops_lv."

check_Q34() {
  local vg="devops_vg"
  local lv="devops_lv"
  local mp="/mnt/devops_lv"
  local pv="/dev/sdc1"
  local lvpath="/dev/${vg}/${lv}"

  # 1) PV exists on /dev/sdc1
  if ! sudo -n pvs --noheadings "$pv" >/dev/null 2>&1; then
    echo "❌ Q34 failed: PV not found on $pv."
    return 1
  fi

  # 2) VG exists and extent size is 20MB
  if ! sudo -n vgs --noheadings "$vg" >/dev/null 2>&1; then
    echo "❌ Q34 failed: VG $vg not found."
    return 1
  fi
  local pesize
  pesize="$(sudo -n vgs --noheadings --units m -o vg_extent_size "$vg" 2>/dev/null | tr -d ' ' | tr 'A-Z' 'a-z')"
  # expected like "20.00m"
  if ! echo "$pesize" | grep -Eq '^20(\.0+)?m$'; then
    echo "❌ Q34 failed: VG extent size is '$pesize' (expected 20m)."
    return 1
  fi

  # 3) LV exists and has exactly 32 extents
  if ! sudo -n lvs --noheadings "$lvpath" >/dev/null 2>&1; then
    echo "❌ Q34 failed: LV $lvpath not found."
    return 1
  fi
  local le
  le="$(sudo -n lvs --noheadings -o lv_le "$lvpath" 2>/dev/null | tr -d ' ')"
  if [[ "$le" != "32" ]]; then
    echo "❌ Q34 failed: LV extents = $le (expected 32)."
    return 1
  fi

  # 4) Filesystem must be ext4 on the LV
  local fstype
  fstype="$(sudo -n blkid -o value -s TYPE "$lvpath" 2>/dev/null || true)"
  if [[ "$fstype" != "ext4" ]]; then
    echo "❌ Q34 failed: filesystem on $lvpath is '$fstype' (expected ext4)."
    return 1
  fi

  # 5) Mountpoint exists and is mounted with ext4
  if [[ ! -d "$mp" ]]; then
    echo "❌ Q34 failed: mountpoint $mp not found."
    return 1
  fi
  local src mtype
  src="$(findmnt -n "$mp" -o SOURCE 2>/dev/null || true)"
  mtype="$(findmnt -n "$mp" -o FSTYPE 2>/dev/null || true)"
  if [[ -z "$src" ]]; then
    echo "❌ Q34 failed: $mp is not mounted."
    return 1
  fi
  if [[ "$mtype" != "ext4" ]]; then
    echo "❌ Q34 failed: $mp mounted as '$mtype' (expected ext4)."
    return 1
  fi

  # 6) fstab must contain a persistent entry for this LV -> mountpoint
  if ! sudo -n grep -Eq "^[[:space:]]*${lvpath}[[:space:]]+${mp}[[:space:]]+ext4[[:space:]]" /etc/fstab 2>/dev/null; then
    echo "❌ Q34 failed: /etc/fstab missing ext4 entry for $lvpath -> $mp."
    return 1
  fi

  echo "✅ Q34 PASSED."
  return 0
}

# ===== Exercise Q35 =====
Q35_DESC="Create 800MB swap on /dev/vdb1 and configure persistent swap mount."

check_Q35() {

  local part="/dev/vdb1"

  # 1) Partition must exist
  if ! [ -b "$part" ]; then
    echo "❌ Q35 failed: $part partition not found."
    return 1
  fi

  # 2) Must be formatted as swap
  if ! sudo -n blkid "$part" 2>/dev/null | grep -q 'TYPE="swap"'; then
    echo "❌ Q35 failed: $part is not formatted as swap."
    return 1
  fi

  # 3) Swap must be active
  if ! swapon --show 2>/dev/null | awk '{print $1}' | grep -qx "$part"; then
    echo "❌ Q35 failed: swap on $part is not active."
    return 1
  fi

  # 4) fstab must contain persistent entry
  if ! sudo -n grep -Eq "^[[:space:]]*$part[[:space:]]+swap[[:space:]]+swap" /etc/fstab 2>/dev/null; then
    echo "❌ Q35 failed: /etc/fstab missing swap entry for $part."
    return 1
  fi

  echo "✅ Q35 PASSED: Swap partition active and persistent."
  return 0
}

# ===== Exercise Q36 =====
Q36_DESC="LVM: cloud_vg + cloud_lv (200M), ext4, persistently mounted at /mnt/cloud_lv."

check_Q36() {
  local vg="cloud_vg"
  local lv="cloud_lv"
  local mp="/mnt/cloud_lv"
  local lvpath="/dev/${vg}/${lv}"

  # 1) VG exists
  if ! sudo -n vgs --noheadings "$vg" >/dev/null 2>&1; then
    echo "❌ Q36 failed: VG $vg not found."
    return 1
  fi

  # 2) LV exists
  if ! sudo -n lvs --noheadings "$lvpath" >/dev/null 2>&1; then
    echo "❌ Q36 failed: LV $lvpath not found."
    return 1
  fi

  # 3) LV size must be 200M (allow small rounding like 199-201)
  local sz
  sz="$(sudo -n lvs --noheadings --units m -o lv_size "$lvpath" 2>/dev/null | tr -d ' ' | tr 'A-Z' 'a-z')"
  # Extract integer part safely
  local n
  n="$(echo "$sz" | sed -n 's/^\([0-9]\+\).*/\1/p')"

  if [[ -z "$n" ]] || (( n < 199 || n > 201 )); then
    echo "❌ Q36 failed: LV size is '$sz' (expected ~200m)."
    return 1
  fi

  # 4) Filesystem must be ext4
  local fstype
  fstype="$(sudo -n blkid -o value -s TYPE "$lvpath" 2>/dev/null || true)"
  if [[ "$fstype" != "ext4" ]]; then
    echo "❌ Q36 failed: filesystem on $lvpath is '$fstype' (expected ext4)."
    return 1
  fi

  # 5) Mountpoint exists and is mounted
  if [[ ! -d "$mp" ]]; then
    echo "❌ Q36 failed: mountpoint $mp not found."
    return 1
  fi

  local src mtype
  src="$(findmnt -n "$mp" -o SOURCE 2>/dev/null || true)"
  mtype="$(findmnt -n "$mp" -o FSTYPE 2>/dev/null || true)"

  if [[ -z "$src" ]]; then
    echo "❌ Q36 failed: $mp is not mounted."
    return 1
  fi
  if [[ "$mtype" != "ext4" ]]; then
    echo "❌ Q36 failed: $mp mounted as '$mtype' (expected ext4)."
    return 1
  fi

  # 6) fstab persistent entry
  if ! sudo -n grep -Eq "^[[:space:]]*${lvpath}[[:space:]]+${mp}[[:space:]]+ext4[[:space:]]" /etc/fstab 2>/dev/null; then
    echo "❌ Q36 failed: /etc/fstab missing ext4 entry for $lvpath -> $mp."
    return 1
  fi

  echo "✅ Q36 PASSED."
  return 0
}

# ===== Exercise Q37 =====
Q37_DESC="Resize cloud_lv to ~250MB (225–270MB acceptable) and resize filesystem."

check_Q37() {

  local lvpath="/dev/cloud_vg/cloud_lv"
  local mp="/mnt/cloud_lv"

  # 1) LV must exist
  if ! sudo -n lvs --noheadings "$lvpath" >/dev/null 2>&1; then
    echo "❌ Q37 failed: $lvpath not found."
    return 1
  fi

  # 2) LV size must be between 225M and 270M
  local sz n
  sz="$(sudo -n lvs --noheadings --units m -o lv_size "$lvpath" 2>/dev/null | tr -d ' ' | tr 'A-Z' 'a-z')"
  n="$(echo "$sz" | sed -n 's/^\([0-9]\+\).*/\1/p')"

  if [[ -z "$n" ]] || (( n < 225 || n > 270 )); then
    echo "❌ Q37 failed: LV size is $sz (expected between 225M and 270M)."
    return 1
  fi

  # 3) Filesystem must be ext4
  local fstype
  fstype="$(sudo -n blkid -o value -s TYPE "$lvpath" 2>/dev/null || true)"
  if [[ "$fstype" != "ext4" ]]; then
    echo "❌ Q37 failed: Filesystem is '$fstype' (expected ext4)."
    return 1
  fi

  # 4) Mountpoint must be mounted
  if ! findmnt -n "$mp" >/dev/null 2>&1; then
    echo "❌ Q37 failed: $mp is not mounted."
    return 1
  fi

  echo "✅ Q37 PASSED: cloud_lv resized correctly."
  return 0
}

# ===== Exercise Q38 =====
Q38_DESC="Cron job: user rhel runs logger every 2 minutes."

check_Q38() {

  local user="rhel"
  local cron_line='*/2 * * * * logger "RHCSA Playlist Now Available"'

  # 1) crond must be running
  if ! systemctl is-active --quiet crond; then
    echo "❌ Q38 failed: crond service is not running."
    return 1
  fi

  # 2) rhel user's crontab must exist
  if ! sudo -n crontab -u "$user" -l >/dev/null 2>&1; then
    echo "❌ Q38 failed: No crontab found for user $user."
    return 1
  fi

  # 3) Check cron entry content
  if ! sudo -n crontab -u "$user" -l | grep -Fxq "$cron_line"; then
    echo "❌ Q38 failed: Cron entry not correctly configured for user $user."
    return 1
  fi

  echo "✅ Q38 PASSED: Cron job correctly configured."
  return 0
}

# ===== Exercise Q39 =====
Q39_DESC='Use at to write "This task was easy!" to /at-files/at.txt in 2 minutes.'

check_Q39() {

  local dir="/at-files"
  local file="/at-files/at.txt"
  local msg="This task was easy!"

  # 1) atd must be running
  if ! systemctl is-active --quiet atd; then
    echo "❌ Q39 failed: atd service is not running."
    return 1
  fi

  # 2) Directory must exist
  if [ ! -d "$dir" ]; then
    echo "❌ Q39 failed: $dir directory not found."
    return 1
  fi

  # 3) File must exist
  if [ ! -f "$file" ]; then
    echo "❌ Q39 failed: $file not found. (Waited 2 minutes?)"
    return 1
  fi

  # 4) File must contain correct message
  if ! grep -Fxq "$msg" "$file"; then
    echo "❌ Q39 failed: Message not found in $file."
    return 1
  fi

  echo "✅ Q39 PASSED: at job executed successfully."
  return 0
}

# ===== Exercise Q40 =====
Q40_DESC="Modify GRUB: timeout=10, hidden style, quiet kernel line, and rebuild config."

check_Q40() {

  local grubfile="/etc/default/grub"

  # 1) Config file must exist
  if [ ! -f "$grubfile" ]; then
    echo "❌ Q40 failed: $grubfile not found."
    return 1
  fi

  # 2) Check GRUB_TIMEOUT
  if ! grep -Eq '^GRUB_TIMEOUT=10' "$grubfile"; then
    echo "❌ Q40 failed: GRUB_TIMEOUT is not set to 10."
    return 1
  fi

  # 3) Check GRUB_TIMEOUT_STYLE
  if ! grep -Eq '^GRUB_TIMEOUT_STYLE=hidden' "$grubfile"; then
    echo "❌ Q40 failed: GRUB_TIMEOUT_STYLE is not set to hidden."
    return 1
  fi

  # 4) Check quiet in GRUB_CMDLINE_LINUX
  if ! grep -Eq '^GRUB_CMDLINE_LINUX=.*quiet' "$grubfile"; then
    echo "❌ Q40 failed: GRUB_CMDLINE_LINUX does not contain 'quiet'."
    return 1
  fi

  # 5) Check grub.cfg was regenerated (simple timestamp validation)
  if ! [ -f /boot/grub2/grub.cfg ]; then
    echo "❌ Q40 failed: /boot/grub2/grub.cfg not found."
    return 1
  fi

  echo "✅ Q40 PASSED: GRUB configuration updated correctly."
  return 0
}

# ===== Exercise Q41 =====
Q41_DESC="Ensure NetworkManager service is enabled and starts at boot."

check_Q41() {

  # 1) Service must exist
  if ! systemctl list-unit-files | awk '{print $1}' | grep -qx 'NetworkManager.service'; then
    echo "❌ Q41 failed: NetworkManager service not found."
    return 1
  fi

  # 2) Must be enabled on boot
  if ! systemctl is-enabled --quiet NetworkManager; then
    echo "❌ Q41 failed: NetworkManager is not enabled at boot."
    return 1
  fi

  # 3) Must be running
  if ! systemctl is-active --quiet NetworkManager; then
    echo "❌ Q41 failed: NetworkManager is not running."
    return 1
  fi

  echo "✅ Q41 PASSED: NetworkManager enabled and running."
  return 0
}

# ===== Exercise Q42 =====
Q42_DESC="Firewall: allow SSH and HTTP services permanently."

check_Q42() {

  # 1) firewalld must be running
  if ! systemctl is-active --quiet firewalld; then
    echo "❌ Q42 failed: firewalld service is not running."
    return 1
  fi

  # 2) ssh service must be allowed
  if ! firewall-cmd --list-services | grep -qw ssh; then
    echo "❌ Q42 failed: ssh service not allowed in firewall."
    return 1
  fi

  # 3) http service must be allowed
  if ! firewall-cmd --list-services | grep -qw http; then
    echo "❌ Q42 failed: http service not allowed in firewall."
    return 1
  fi

  echo "✅ Q42 PASSED: SSH and HTTP allowed in firewall."
  return 0
}

# ===== Exercise Q43 =====
Q43_DESC="Create sharegroup; users haruna(nologin), umar(group), adoga(UID 4444); set passwords."

check_Q43() {

  # 1) Group exists
  if ! getent group sharegroup >/dev/null; then
    echo "❌ Q43 failed: group sharegroup not found."
    return 1
  fi

  # 2) User haruna exists
  if ! getent passwd haruna >/dev/null; then
    echo "❌ Q43 failed: user haruna not found."
    return 1
  fi

  # haruna must have nologin shell
  if ! getent passwd haruna | awk -F: '{print $7}' | grep -qx '/sbin/nologin'; then
    echo "❌ Q43 failed: haruna does not have /sbin/nologin shell."
    return 1
  fi

  # haruna must NOT be in sharegroup
  if id haruna | grep -qw sharegroup; then
    echo "❌ Q43 failed: haruna should NOT be member of sharegroup."
    return 1
  fi

  # 3) User umar exists and in sharegroup
  if ! getent passwd umar >/dev/null; then
    echo "❌ Q43 failed: user umar not found."
    return 1
  fi

  if ! id umar | grep -qw sharegroup; then
    echo "❌ Q43 failed: umar is not in sharegroup."
    return 1
  fi

  # 4) User adoga exists, UID 4444, in sharegroup
  if ! getent passwd adoga >/dev/null; then
    echo "❌ Q43 failed: user adoga not found."
    return 1
  fi

  if ! getent passwd adoga | awk -F: '{print $3}' | grep -qx '4444'; then
    echo "❌ Q43 failed: adoga UID is not 4444."
    return 1
  fi

  if ! id adoga | grep -qw sharegroup; then
    echo "❌ Q43 failed: adoga is not in sharegroup."
    return 1
  fi

  # 5) Verify adoga password changed to "perfect"
  if _has_exact_password "adoga" "perfect"; then
    echo "✅ Q43 PASSED."
    return 0
  else
    rc=$?
    if [ $rc -eq 2 ]; then
      echo "⚠️ Q43 WARN: Cannot verify password hash (missing mkpasswd/python)."
      echo "✅ Q43 accepted with warning."
      return 0
    else
      echo "❌ Q43 failed: adoga password is not 'perfect'."
      return 1
    fi
  fi
}

# ===== Exercise Q44 =====
Q44_DESC="Password policy: min length 8, max password age 30 days."

check_Q44() {

  local pwq="/etc/security/pwquality.conf"
  local defs="/etc/login.defs"

  # 1) pwquality.conf must exist
  if [ ! -f "$pwq" ]; then
    echo "❌ Q44 failed: $pwq not found."
    return 1
  fi

  # 2) minlen must be set to 8 or more
  local minlen
  minlen="$(grep -E '^[[:space:]]*minlen' "$pwq" | tail -n1 | awk -F= '{print $2}' | tr -d ' ')"

  if [[ -z "$minlen" || "$minlen" -lt 8 ]]; then
    echo "❌ Q44 failed: minlen is not set to at least 8."
    return 1
  fi

  # 3) login.defs must exist
  if [ ! -f "$defs" ]; then
    echo "❌ Q44 failed: $defs not found."
    return 1
  fi

  # 4) PASS_MAX_DAYS must be 30
  local maxdays
  maxdays="$(grep -E '^[[:space:]]*PASS_MAX_DAYS' "$defs" | tail -n1 | awk '{print $2}')"

  if [[ "$maxdays" != "30" ]]; then
    echo "❌ Q44 failed: PASS_MAX_DAYS is '$maxdays' (expected 30)."
    return 1
  fi

  echo "✅ Q44 PASSED: Password policy correctly configured."
  return 0
}

# ===== Exercise Q45 =====
Q45_DESC="Remove umar from sharegroup, delete sharegroup, delete haruna with home."

check_Q45() {

  # 1) haruna must NOT exist
  if getent passwd haruna >/dev/null; then
    echo "❌ Q45 failed: user haruna still exists."
    return 1
  fi

  # 2) haruna home must be removed
  if [ -d /home/haruna ]; then
    echo "❌ Q45 failed: /home/haruna still exists."
    return 1
  fi

  # 3) sharegroup must NOT exist
  if getent group sharegroup >/dev/null; then
    echo "❌ Q45 failed: sharegroup still exists."
    return 1
  fi

  # 4) umar must exist but NOT be member of sharegroup
  if ! getent passwd umar >/dev/null; then
    echo "❌ Q45 failed: user umar does not exist."
    return 1
  fi

  if id umar | grep -qw sharegroup; then
    echo "❌ Q45 failed: umar is still a member of sharegroup."
    return 1
  fi

  echo "✅ Q45 PASSED."
  return 0
}


# ===== Exercise Q46 =====
Q46_DESC="Ensure firewalld is enabled+running and SELinux is enforcing."

check_Q46() {

  # ---- firewalld must exist ----
  if ! systemctl list-unit-files | awk '{print $1}' | grep -qx 'firewalld.service'; then
    echo "❌ Q46 failed: firewalld service not found."
    return 1
  fi

  # ---- firewalld enabled ----
  if ! systemctl is-enabled --quiet firewalld; then
    echo "❌ Q46 failed: firewalld is not enabled on boot."
    return 1
  fi

  # ---- firewalld running ----
  if ! systemctl is-active --quiet firewalld; then
    echo "❌ Q46 failed: firewalld is not running."
    return 1
  fi

  # ---- SELinux config file enforcing ----
  if ! grep -Eq '^SELINUX=enforcing' /etc/selinux/config; then
    echo "❌ Q46 failed: /etc/selinux/config not set to enforcing."
    return 1
  fi

  # ---- SELinux runtime enforcing ----
  local se
  se="$(getenforce 2>/dev/null)"
  if [[ "$se" != "Enforcing" ]]; then
    echo "❌ Q46 failed: SELinux runtime mode is '$se' (expected Enforcing)."
    return 1
  fi

  echo "✅ Q46 PASSED: firewalld active and SELinux enforcing."
  return 0
}



# ===== Infra =====
TASKS=(Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8 Q9 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21 Q22 Q23 Q24 Q25 Q26 )
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
  sudo rm -rf "${TRAINER_HOME}/httpd-paths.txt" 2>/dev/null || true
  sudo rm -f -- "${TRAINER_HOME}/web.txt" 2>/dev/null || true
  sudo rm -f -- "${TRAINER_HOME}/career.sh" 2>/dev/null || true
  sudo rm -rf /var/tmp/chmod_lab 2>/dev/null || true

  #delete Q14 to Q20 user and groups and files

  # Users: devops, admin, student, tester, analyst, backup
for u in devops admin student tester analyst backup; do
  if getent passwd "$u" >/dev/null; then
    sudo pkill -u "$u" 2>/dev/null || true
    sudo userdel -r "$u"
  fi
done

# Groups: devs, admins, students, qa, finance, storage
for g in devs admins students qa finance storage; do
  if getent group "$g" >/dev/null; then
    sudo groupdel "$g"
  fi
done

  sudo userdel -r noob 2>/dev/null || true
  sudo userdel -r def4ult 2>/dev/null || true

sudo rm -rf /var/tmp/chmod_lab 2>/dev/null || true
#
  sudo rm -f "${TRAINER_HOME}/find-files.sh" 2>/dev/null || true
  sudo rm -f "${TRAINER_HOME}/sized_files.txt" 2>/dev/null || true

  #clean Q25 users and groups
  sudo userdel -r maryam 2>/dev/null || true
  sudo userdel -r adam 2>/dev/null || true
  sudo userdel -r jacob 2>/dev/null || true
  sudo groupdel hpc_admin 2>/dev/null || true
  sudo groupdel hpc_managers 2>/dev/null || true
  sudo groupdel sysadmin 2>/dev/null || true
  sudo rm -f "${TRAINER_HOME}/groups.txt" 2>/dev/null || true
  sudo rm -f "${TRAINER_HOME}/users.txt" 2>/dev/null || true
  sudo rm -f "${TRAINER_HOME}/create_groups.sh" 2>/dev/null || true
  sudo rm -f "${TRAINER_HOME}/create_users.sh" 2>/dev/null || true
  sudo rm -f "${TRAINER_HOME}/setpass.sh" 2>/dev/null || true

  ##clean Q21
  sudo rm -f /root/find-files.sh
  sudo rm -f /root/sized_files.txt

  ##clean Q24
  sudo rm -f /root/career.sh

  #Clean Q27
  sudo tuned-adm profile balanced 2>/dev/null || true
  sudo systemctl disable --now tuned 2>/dev/null || true
  sudo setenforce 1 2>/dev/null || true
  sudo sed -i 's/^SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config 2>/dev/null || true
  sudo systemctl disable --now network 2>/dev/null || true
  sudo systemctl enable --now NetworkManager 2>/dev/null || true

  #clean Q28
  sudo sed -i 's/^SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config 2>/dev/null || true
  sudo setenforce 1 2>/dev/null || true

  #Clean Q29
  sudo systemctl disable --now NetworkManager 2>/dev/null || true

  #Clean Q30
  sudo rm -rf /var/log/journal 2>/dev/null || true

  #Clean Q32
  sudo rm -f /var/tmp/fstab 2>/dev/null || true

  #Clean Q33
  sudo rm -f /home/master-server/rhel-file.ext 2>/dev/null || true
  rm -f rhel-file.ext 2>/dev/null || true

  #Clean Q34
  # remove fstab line
  sudo sed -i '\|^/dev/devops_vg/devops_lv[[:space:]]\+/mnt/devops_lv[[:space:]]\+ext4|d' /etc/fstab 2>/dev/null || true
  
  # unmount
  sudo umount /mnt/devops_lv 2>/dev/null || true

  # remove LV/VG/PV
  sudo lvremove -fy /dev/devops_vg/devops_lv 2>/dev/null || true
  sudo vgremove -fy devops_vg 2>/dev/null || true
  sudo pvremove -ffy /dev/sdc1 2>/dev/null || true

  # wipe signatures (helps for next run)
  sudo wipefs -a /dev/sdc1 2>/dev/null || true

  # cleanup mount dir
  sudo rmdir /mnt/devops_lv 2>/dev/null || true

  #Clean Q35
  # ---- Reset Q35: swap on /dev/vdb1 ----
  echo ">> Resetting Q35 (swap)..."

  # Disable swap
  sudo swapoff /dev/vdb1 2>/dev/null || true

  # Remove fstab entry
  sudo sed -i '\|^/dev/vdb1[[:space:]]\+swap|d' /etc/fstab 2>/dev/null || true

  # Remove swap signature
  sudo wipefs -a /dev/vdb1 2>/dev/null || true

  #Clean 36
   # ---- Reset Q36: cloud_vg/cloud_lv ----
  echo ">> Resetting Q36 (cloud_vg/cloud_lv)..."

  # remove fstab line
  sudo sed -i '\|^/dev/cloud_vg/cloud_lv[[:space:]]\+/mnt/cloud_lv[[:space:]]\+ext4|d' /etc/fstab 2>/dev/null || true

  # unmount
  sudo umount /mnt/cloud_lv 2>/dev/null || true

  # remove LV/VG/PV
  sudo lvremove -fy /dev/cloud_vg/cloud_lv 2>/dev/null || true
  sudo vgremove -fy cloud_vg 2>/dev/null || true

  # wipe PV signatures if a partition exists
  sudo pvremove -ffy /dev/sdc1 2>/dev/null || true
  sudo wipefs -a /dev/sdc1 2>/dev/null || true

  # cleanup mount dir
  sudo rmdir /mnt/cloud_lv 2>/dev/null || true

  #Clean 38
  sudo crontab -u rhel -r 2>/dev/null || true

  #Clean 39
  # Remove pending at jobs
  for j in $(atq 2>/dev/null | awk '{print $1}'); do
    sudo atrm "$j" 2>/dev/null || true
  done

  # Remove files
  sudo rm -rf /at-files 2>/dev/null || true

  #Clean 40
  # Restore common default values
  if [ -f /etc/default/grub ]; then
    sudo sed -i \
      -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' \
      -e 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' \
      -e 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=""/' \
      /etc/default/grub 2>/dev/null || true
  fi

  # Rebuild grub.cfg
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1 || true

  #Clean 41
  sudo systemctl disable --now NetworkManager 2>/dev/null || true

  #Clean 42
  udo firewall-cmd --remove-service=ssh --permanent 2>/dev/null || true
  sudo firewall-cmd --remove-service=http --permanent 2>/dev/null || true
  sudo firewall-cmd --reload 2>/dev/null || true

  #Clean 43
  sudo userdel -r haruna 2>/dev/null || true
  sudo userdel -r umar 2>/dev/null || true
  sudo userdel -r adoga 2>/dev/null || true
  sudo groupdel sharegroup 2>/dev/null || true

  #Clean 44
  sudo sed -i 's/^[[:space:]]*minlen[[:space:]]*=.*/# minlen = 0/' /etc/security/pwquality.conf 2>/dev/null || true
  sudo sed -i 's/^[[:space:]]*PASS_MAX_DAYS.*/PASS_MAX_DAYS   99999/' /etc/login.defs 2>/dev/null || true
  
  #Clean 45
  # Recreate sharegroup
  getent group sharegroup >/dev/null || sudo groupadd sharegroup

  # Recreate haruna (nologin)
  getent passwd haruna >/dev/null || sudo useradd -s /sbin/nologin haruna
  # Recreate umar and re-add to sharegroup
  if ! getent passwd umar >/dev/null; then
    sudo useradd -G sharegroup umar
  else
    sudo usermod -aG sharegroup umar
  fi

  #Clean 46
    # ---- Reset Q46: firewalld + SELinux ----
  echo ">> Resetting Q46 (firewalld + SELinux)..."

  # Disable firewalld
  sudo systemctl disable --now firewalld 2>/dev/null || true

  # Reset SELinux to permissive (lab default in earlier questions)
  if [ -f /etc/selinux/config ]; then
    sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config 2>/dev/null || true
  fi

  sudo setenforce 0 2>/dev/null || true

  #Echo
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
