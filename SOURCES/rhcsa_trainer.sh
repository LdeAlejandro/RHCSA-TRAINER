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
Q1_DESC="On the local system, create a file named hello.txt in the current working directory. The file must contain the text 'hello world'. Save the file and ensure the content is written successfully."

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
Q2_DESC="Configure SSH key-based authentication between the local system and a remote host. Ensure the user can log in to the remote system without being prompted for a password."

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
Q3_DESC="As an administrator, review recent system activity. Examine system logs, including authentication-related events, and verify the status of the SSH service using available log sources."

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
Q4_DESC='A file named "move me to document and copy me to backup" exists in /trainer/files. Move the file to /trainer/Documents and then create a copy of it in /trainer/DocumentBackup.'
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
Q5_DESC='On the system, identify all entries containing the string "Listen" in the Apache HTTP Server configuration file. Save the results to /root/web.txt.'
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
Q6_DESC="Create a directory named ~/vaults. Archive the entire /etc directory into a gzip-compressed tar file named etc_vault.tar.gz and store it in ~/vaults."

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
Q7_DESC="Create a directory named /shorts. Inside this directory create a file named file_a. Create a symbolic link named /file_b that points to /shorts/file_a."

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
Q8_DESC="A file named /hardfiles/file_data already exists on the system. Create a hard link named /file_c that references this file."
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
Q9_DESC="Create the directory /bigfiles. Locate all regular files under /usr that are larger than 3 MB and smaller than 10 MB, then copy them to /bigfiles."

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
Q10_DESC="Create the directory /var/tmp/twenty. Locate all regular files under /etc that were modified more than 120 days ago and copy them to /var/tmp/twenty."

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
Q11_DESC="Create the directory /var/tmp/rhel-files. Locate all regular files under /tmp owned by the user rhel and copy them to /var/tmp/rhel-files."

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
Q12_DESC="Locate all files named httpd.conf on the system and save their absolute paths to /root/httpd-paths.txt."


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
Q13_DESC="Copy /etc/fstab to /var/tmp. Configure the copied file so that it is owned by root:root and cannot be executed by any user."
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
Q14_DESC="Configure /var/tmp/chmod_lab/public.log so that it is owned by root:root and all users have full access to the file."
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
Q15_DESC="Configure /var/tmp/chmod_lab/script.sh with the following requirements:
- Owner: devops
- Group: devs
- Owner must have read, write, and execute permissions
- Group members must have read and execute permissions
- Other users must have read and execute permissions

Ensure the required user and group exist on the system."
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
Q16_DESC="Configure /var/tmp/chmod_lab/secret.txt with the following requirements:
- Owner: admin
- Group: admins
- Only the owner must have access to the file.
- The owner must be able to read, write, and execute the file."
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
Q17_DESC="Configure /var/tmp/chmod_lab/document.txt with the following requirements:
- Owner: student
- Group: students
- The owner must have read and write permissions.
- All other users must have read-only access."
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
Q18_DESC="Configure /var/tmp/chmod_lab/private.key with the following requirements:
- Owner: tester
- Group: qa
- The owner must have read and write permissions.
- No other user should have access to the file."
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
Q19_DESC="Configure /var/tmp/chmod_lab/readme.md with the following requirements:
- Owner: analyst
- Group: finance
- The owner must have read-only access.
- No other user should have access to the file."
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
Q20_DESC="Configure /var/tmp/chmod_lab/hidden.conf with the following requirements:
- Owner: backup
- Group: storage
- No user should have any permissions on the file."
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
Q21_DESC="Create a shell script named /root/find-files.sh that locates all regular files under /usr with a size between 30 KB and 50 KB. The script must save the results to /root/sized_files.txt."
check_Q21() {
  local script="/root/find-files.sh"
  local output="/root/sized_files.txt"
  local expected
  local actual
  local rc

  # 1) The script must exist
  if ! sudo -n test -f "$script" 2>/dev/null; then
    echo "❌ Q21 failed: Script $script not found."
    return 1
  fi

  # 2) The script must be executable
  if ! sudo -n test -x "$script" 2>/dev/null; then
    echo "❌ Q21 failed: Script $script is not executable."
    return 1
  fi

  # 3) Execute the script only when the output does not exist
  if ! sudo -n test -f "$output" 2>/dev/null; then
    sudo -n bash "$script" </dev/null >/dev/null 2>&1
    rc=$?

    if (( rc != 0 )); then
      echo "❌ Q21 failed: Script execution failed with status $rc."
      return 1
    fi
  fi

  # 4) The output file must exist after executing the script
  if ! sudo -n test -f "$output" 2>/dev/null; then
    echo "❌ Q21 failed: Output file $output was not created."
    return 1
  fi

  # 5) Create temporary files for comparison
  expected="$(mktemp)" || {
    echo "❌ Q21 failed: Could not create temporary file."
    return 1
  }

  actual="$(mktemp)" || {
    rm -f "$expected"
    echo "❌ Q21 failed: Could not create temporary file."
    return 1
  }

  # 6) Generate the expected result
  sudo -n find /usr \
    -type f \
    -size +30k \
    -size -50k \
    -print 2>/dev/null |
    LC_ALL=C sort > "$expected"

  # 7) Read and normalize the student's result
  if ! sudo -n cat "$output" 2>/dev/null |
    sed '/^[[:space:]]*$/d' |
    LC_ALL=C sort > "$actual"; then

    rm -f "$expected" "$actual"
    echo "❌ Q21 failed: Could not read $output."
    return 1
  fi

  # 8) Compare expected and actual results
  if cmp -s "$expected" "$actual"; then
    rm -f "$expected" "$actual"
    echo "✅ Q21 passed: Output file contains the correct files."
    return 0
  fi

  rm -f "$expected" "$actual"

  echo "❌ Q21 failed: $output does not contain the expected files."
  return 1
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
Q22_DESC="Create a local user account named noob with the password Aa7338!!. Configure the account so that the user is required to change the password at the next login."
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
Q23_DESC="Create a local user account named def4ult and assign the password Aa578!!??. After the account is created, change the password to C546#Ab!."
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
Q24_DESC="Create a shell script named career.sh in the root user's home directory with the following behavior:

- When executed with the argument me, it must display:
  \"Yes, I'm a Systems Engineer.\"
- When executed with the argument they, it must display:
  \"Okay, they do cloud engineering.\"
- For invalid or missing arguments, it must display:
  \"Usage: ./career.sh me|they\"
- The script must have permissions set to 755"
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
Q25_DESC='On node1, create shell scripts that automate user and group administration according to the requirements below.

Requirements:

- Create groups using the specified group names and GIDs.
- Create users using the specified usernames, UIDs, and supplementary group memberships.
- Configure the password Strong!2025 for users maryam, adam, and jacob.

Groups and GIDs:

```bash
hpc_admin:9090
hpc_managers:8080
sysadmin:7070
```

Users, UIDs, and Groups:

```bash
maryam:2030:hpc_admin,hpc_managers
adam:2040:sysadmin
jacob:2050:hpc_admin
```

The solution must be implemented using the following scripts:

```bash
create_groups.sh
create_users.sh
setpass.sh
```

### Params:

```bash
maryam:2030:hpc_admin,hpc_managers
adam:2040:sysadmin
jacob:2050:hpc_admin
```'

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
Q26_DESC="Reset the root password on the local system by using GRUB recovery mode. Set the root password to hoppy and ensure the system can boot normally after the password reset."

check_Q26() {
  local passwd_test="hoppy"

  echo "$passwd_test" | su -c "exit" root &>/dev/null

  if [ $? -eq 0 ]; then
    echo "✅ Q26 | PASS | root password reset to 'hoppy'"
    return 0
  fi

  echo "❌ Q26 | FAIL | root password is not 'hoppy'"
  return 1
}

# ===== Exercise Q27 =====
Q27_DESC="On rhel-server, review the system tuning configuration and apply the recommended tuning profile. Configure SELinux to operate in permissive mode and ensure the appropriate network service is enabled and configured to start automatically at boot.

### check if tuned is intall and running change the tune to the recommended one"

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
Q28_DESC="Configure SELinux so that the system operates in permissive mode after a reboot. Verify that the configuration persists across system restarts."

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
Q29_DESC="Ensure that the system networking service is enabled and configured to start automatically during system boot."


check_Q29() {

  if ! systemctl is-enabled --quiet NetworkManager; then
    echo "❌ Q29 failed: NetworkManager is not enabled on boot."
    return 1
  fi

  if ! systemctl is-active --quiet NetworkManager; then
    echo "❌ Q29 failed: NetworkManager is not running."
    return 1
  fi

  echo "✅ Q29 PASSED: NetworkManager enabled and running."
  return 0
}

# ===== Exercise Q30 =====
Q30_DESC="Configure persistent systemd journal logging so that log data is retained across reboots."


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
Q31_DESC="A workload testing utility is installed on the system. Perform the following tasks:

- Start a stress-ng process with a niceness value of 19.
- Modify the running process so that its niceness value becomes 10.
- Terminate the process when finished."

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
Q32_DESC="Copy the file /etc/fstab to /var/tmp and configure access according to the following requirements:

- The file owner must be root.
- The file must not be executable by any user.
- User adam must have read and write access.
- User maryam must have no access.
- All other users must have read-only access."

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
Q33_DESC="On rhel, create a file named rhel-file.txt in the current user's environment and securely transfer it to the home directory of user master-server on main-server."

check_Q33() {

  local FILE="rhel-file.txt"
  local REMOTE_USER="${Q33_USER:-master-server}"
  local REMOTE_HOST="${Q33_HOST:-192.168.15.14}"
  local REMOTE_DEST="/home/master-server/rhel-file.txt"
  local LOG="$RHCSA_SHM_DIR/cmd.log"

  # 1) Local file must exist
  if [ ! -f "$FILE" ]; then
    echo "❌ Q33 failed: $FILE not found in current directory."
    return 1
  fi

  # 2) scp command must be detected first
  if [[ ! -f "$LOG" ]] || ! grep -Eq 'scp[[:space:]]+.*rhel-file\.txt[[:space:]]+master-server@' "$LOG"; then
    echo "❌ Q33 failed: scp command not detected in monitored session."
    echo "Hint: scp rhel-file.txt ${REMOTE_USER}@${REMOTE_HOST}:/home/master-server/"
    return 1
  fi

  # 3) Try remote validation using SSH key only.
  # This avoids hanging or asking for a password during the automated check.
  if ssh -o BatchMode=yes \
         -o PasswordAuthentication=no \
         -o PubkeyAuthentication=yes \
         -o StrictHostKeyChecking=accept-new \
         -o ConnectTimeout=5 \
         "${REMOTE_USER}@${REMOTE_HOST}" \
         "test -f '$REMOTE_DEST'" >/dev/null 2>&1; then
    echo "✅ Q33 PASSED: File copied successfully to remote host."
    return 0
  fi

  # 4) If key auth is not ready, don't hang asking for password.
  echo "⚠️ Q33 could not validate remote file using SSH key authentication."
  echo "   The scp command was detected, but automatic SSH validation needs passwordless access."
  echo
  echo "   First configure key-based SSH, for example:"
  echo "   ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST}"
  echo
  echo "   Then verify manually:"
  echo "   ssh ${REMOTE_USER}@${REMOTE_HOST} 'test -f ${REMOTE_DEST} && echo OK'"
  echo
  echo "❌ Q33 failed: Remote validation could not be completed automatically."
  return 1
}

# ===== Exercise Q34 =====
Q34_DESC="Create a logical volume named devops_lv using storage provided by /dev/sdc. The logical volume must be created from a volume group named devops_vg with physical extents of 20 MB. Configure the logical volume with 32 extents, create an ext4 filesystem on it, and mount it persistently at /mnt/devops_lv."

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
  if ! echo "$pesize" | grep -Eq '^20([.,]0+)?m$'; then
    echo "❌ Q34 failed: VG extent size is '$pesize' (expected 20m)."
    return 1
  fi

  # 3) LV exists and has exactly 32 extents
  if ! sudo -n lvs --noheadings "$lvpath" >/dev/null 2>&1; then
    echo "❌ Q34 failed: LV $lvpath not found."
    return 1
  fi
  local le
  le="$(sudo -n lvdisplay "$lvpath" 2>/dev/null | awk '/Current LE/ {print $3}')"

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
Q35_DESC="Using the disk /dev/sdd, create an 800 MB swap partition and configure the system so that the swap space is activated automatically after reboot. Verify that the swap space is available."

check_Q35() {

  local part="/dev/sdd2"

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
  if ! sudo -n grep -Eq "^[[:space:]]*$part[[:space:]]+swap[[:space:]]+swap[[:space:]]" /etc/fstab 2>/dev/null; then
    echo "❌ Q35 failed: /etc/fstab missing swap entry for $part."
    return 1
  fi

  echo "✅ Q35 PASSED: Swap partition active and persistent."
  return 0
}

# ===== Exercise Q36 =====
Q36_DESC="On rhel-server, configure local storage according to the following requirements:

- Create a volume group named cloud_vg.
- Create a logical volume named cloud_lv from cloud_vg.
- The logical volume must have a size of 200 MB.
- Create an appropriate filesystem on the logical volume.
- Mount the filesystem and ensure it is available after a system reboot."

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
Q37_DESC="An existing logical volume named cloud_lv requires additional storage.

Resize cloud_lv so that its final size is 250 MB. A final size between 225 MB and 270 MB is acceptable. Ensure the filesystem is resized accordingly."

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
Q38_DESC="Cron Job Configuration

Configure a scheduled task for user rhel-user that records the following message in the system logs every 2 minutes: RHCSA Playlist Now Available
"

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
Q39_DESC='Schedule a one-time job that writes the following text to /at-files/at.txt exactly 2 minutes from now:

```text
This task was easy!
```'

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
Q40_DESC="GRUB Bootloader Modification

Modify the GRUB bootloader configuration with the following requirements:

- Set GRUB_TIMEOUT to 10.
- Set GRUB_TIMEOUT_STYLE to hidden.
- Add the quiet kernel parameter to GRUB_CMDLINE_LINUX.
- Regenerate the GRUB configuration so the changes take effect."

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
Q41_DESC="Ensure that the system network management service is enabled and automatically starts at boot."

check_Q41() {

  if ! systemctl is-enabled --quiet NetworkManager; then
    echo "❌ Q41 failed: NetworkManager is not enabled."
    return 1
  fi

  if ! systemctl is-active --quiet NetworkManager; then
    echo "❌ Q41 failed: NetworkManager is not running."
    return 1
  fi

  echo "✅ Q41 PASSED."
  return 0
}
# ===== Exercise Q42 =====
Q42_DESC="Configure the firewall to allow access to the following services permanently:

- SSH
- HTTP

Apply the configuration so that the changes take effect immediately."

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
Q43_DESC="Create a group named sharegroup and configure the following user accounts:

- haruna must not be able to log in interactively and must not be a member of sharegroup.
- umar must be a member of sharegroup.
- adoga must have UID 4444 and be a member of sharegroup.

Configure the password persward for all users. Afterward, change the password of user adoga to perfect."

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
Q44_DESC="User Password Policies

Configure the system password policy to meet the following requirements:

- Passwords must have a minimum length of 8 characters.
- User passwords must expire after 30 days."

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
Q45_DESC="Perform the following administrative tasks:

- Remove user umar from the sharegroup group.
- Delete the sharegroup group.
- Remove the user haruna and delete the user's home directory."

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
Q46_DESC="Verify that firewalld and SELinux are enabled and active on the system. If firewalld is not running, configure it to start immediately and automatically at boot. Ensure SELinux is configured in enforcing mode."

check_Q46() {

  if ! systemctl is-enabled --quiet firewalld; then
    echo "❌ Q46 failed: firewalld is not enabled on boot."
    return 1
  fi

  if ! systemctl is-active --quiet firewalld; then
    echo "❌ Q46 failed: firewalld is not running."
    return 1
  fi

  if ! grep -Eq '^SELINUX=enforcing' /etc/selinux/config; then
    echo "❌ Q46 failed: /etc/selinux/config not set to enforcing."
    return 1
  fi

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

# ===== Exercise Q47 =====
Q47_DESC="Configure a connection named static-enp0s8 on interface enp0s8 with IPv4 address 192.168.100.50/24, gateway 192.168.100.1, and DNS server 8.8.8.8. Ensure the configuration persists after reboot."
check_Q47() {
  local con="static-enp0s8" iface="enp0s8"
  nmcli -t -f NAME con show | grep -qx "$con" || { echo "❌ Q47 failed: connection $con not found."; return 1; }
  [[ "$(nmcli -g connection.interface-name con show "$con" 2>/dev/null)" == "$iface" ]] || { echo "❌ Q47 failed: $con is not bound to $iface."; return 1; }
  nmcli -g ipv4.addresses con show "$con" | grep -qw '192.168.100.50/24' || { echo "❌ Q47 failed: IPv4 address mismatch."; return 1; }
  [[ "$(nmcli -g ipv4.gateway con show "$con")" == "192.168.100.1" ]] || { echo "❌ Q47 failed: gateway mismatch."; return 1; }
  nmcli -g ipv4.dns con show "$con" | grep -qw '8.8.8.8' || { echo "❌ Q47 failed: DNS mismatch."; return 1; }
  [[ "$(nmcli -g ipv4.method con show "$con")" == "manual" ]] || { echo "❌ Q47 failed: ipv4.method must be manual."; return 1; }
  [[ "$(nmcli -g connection.autoconnect con show "$con")" == "yes" ]] || { echo "❌ Q47 failed: connection is not autoconnect enabled."; return 1; }
  echo "✅ Q47 PASSED."; return 0
}

# ===== Exercise Q48 =====
Q48_DESC="Configure interface enp0s8 with IPv6 address 2001:db8::10/64 and gateway 2001:db8::1. Activate the configuration immediately."
check_Q48() {
  local iface="enp0s8"
  ip -6 addr show dev "$iface" 2>/dev/null | grep -qw '2001:db8::10/64' || { echo "❌ Q48 failed: IPv6 address not active on $iface."; return 1; }
  ip -6 route | grep -Eq '^default via 2001:db8::1 dev enp0s8|2001:db8::1 dev enp0s8' || { echo "❌ Q48 failed: IPv6 gateway/route not active."; return 1; }
  echo "✅ Q48 PASSED."; return 0
}

# ===== Exercise Q49 =====
Q49_DESC="Configure the system hostname as rhcsa-server.example.com and ensure it persists after reboot."
check_Q49() {
  [[ "$(hostnamectl --static 2>/dev/null)" == "rhcsa-server.example.com" ]] || { echo "❌ Q49 failed: static hostname mismatch."; return 1; }
  grep -qx 'rhcsa-server.example.com' /etc/hostname 2>/dev/null || { echo "❌ Q49 failed: /etc/hostname not persistent."; return 1; }
  echo "✅ Q49 PASSED."; return 0
}

# ===== Exercise Q50 =====
Q50_DESC="Configure the active network connection to use DNS servers 1.1.1.1 and 8.8.8.8. Verify that hostname resolution functions correctly."
check_Q50() {
  local con dns
  con="$(nmcli -t -f NAME,DEVICE con show --active | awk -F: '$2!="lo"{print $1; exit}')"
  [[ -n "$con" ]] || { echo "❌ Q50 failed: no active non-loopback connection found."; return 1; }
  dns="$(nmcli -g ipv4.dns con show "$con" 2>/dev/null)"
  echo "$dns" | grep -qw '1.1.1.1' || { echo "❌ Q50 failed: DNS 1.1.1.1 missing on active connection $con."; return 1; }
  echo "$dns" | grep -qw '8.8.8.8' || { echo "❌ Q50 failed: DNS 8.8.8.8 missing on active connection $con."; return 1; }
  getent hosts example.com >/dev/null 2>&1 || { echo "❌ Q50 failed: hostname resolution test failed."; return 1; }
  echo "✅ Q50 PASSED."; return 0
}
 
# ===== Exercise Q51 =====
Q51_DESC="The network connection enp0s8 exists but is currently disconnected. Restore network connectivity and ensure the connection activates automatically at system boot."
check_Q51() {
  local con
  con="$(nmcli -t -f NAME,DEVICE con show | awk -F: '$2=="enp0s8"{print $1; exit}')"
  [[ -n "$con" ]] || { echo "❌ Q51 failed: no connection profile for enp0s8 found."; return 1; }
  nmcli -t -f DEVICE,STATE dev status | grep -q '^enp0s8:connected' || { echo "❌ Q51 failed: enp0s8 is not connected."; return 1; }
  [[ "$(nmcli -g connection.autoconnect con show "$con")" == "yes" ]] || { echo "❌ Q51 failed: autoconnect is not enabled."; return 1; }
  echo "✅ Q51 PASSED."; return 0
}

# ===== Exercise Q52 =====
Q52_DESC="A process named stress-ng is consuming excessive CPU resources. Locate the process and terminate it."
check_Q52() {
  if pgrep -x stress-ng >/dev/null 2>&1; then echo "❌ Q52 failed: stress-ng is still running."; return 1; fi
  local LOG="$RHCSA_SHM_DIR/cmd.log"
  [[ -f "$LOG" ]] && grep -Eq 'pgrep|ps|top|kill|pkill|killall' "$LOG" || { echo "❌ Q52 failed: no process locate/kill command detected in monitored shell."; return 1; }
  echo "✅ Q52 PASSED."; return 0
}

# ===== Exercise Q53 =====
Q53_DESC="Start a process with a niceness value of 15. Modify the running process so that its niceness value becomes 5."
check_Q53() {
  local LOG="$RHCSA_SHM_DIR/cmd.log"
  [[ -f "$LOG" ]] || { echo "❌ Q53 failed: no monitored shell log found."; return 1; }
  grep -Eq 'nice[[:space:]]+-n[[:space:]]+15' "$LOG" || { echo "❌ Q53 failed: nice -n 15 not detected."; return 1; }
  grep -Eq 'renice[[:space:]]+(-n[[:space:]]+)?5' "$LOG" || { echo "❌ Q53 failed: renice to 5 not detected."; return 1; }
  echo "✅ Q53 PASSED."; return 0
}

# ===== Exercise Q54 =====
Q54_DESC="Identify the five processes currently consuming the most memory on the system."
check_Q54() {
  local LOG="$RHCSA_SHM_DIR/cmd.log"
  [[ -f "$LOG" ]] || { echo "❌ Q54 failed: no monitored shell log found."; return 1; }
  grep -Eq 'ps[[:space:]].*(%mem|rss|pmem|--sort[=-]?-?%?mem)|top|htop' "$LOG" || { echo "❌ Q54 failed: memory process inspection command not detected."; return 1; }
  grep -Eq 'head[[:space:]]+-n[[:space:]]+5|head[[:space:]]+-5|top|htop' "$LOG" || { echo "❌ Q54 failed: top five filtering not detected."; return 1; }
  echo "✅ Q54 PASSED."; return 0
}

# ===== Exercise Q55 =====
Q55_DESC="Locate all messages generated by the sshd service during the current boot session."
check_Q55() {
  local LOG="$RHCSA_SHM_DIR/cmd.log"
  [[ -f "$LOG" ]] && grep -Eq 'journalctl[[:space:]].*(-u[[:space:]]+sshd|-b).*' "$LOG" && grep -Eq 'journalctl[[:space:]].*(-b|-u[[:space:]]+sshd).*' "$LOG" || { echo "❌ Q55 failed: expected journalctl -u sshd -b usage."; return 1; }
  echo "✅ Q55 PASSED."; return 0
}

# ===== Exercise Q56 =====
Q56_DESC="Locate all system log messages generated during the last 30 minutes."
check_Q56() {
  local LOG="$RHCSA_SHM_DIR/cmd.log"
  [[ -f "$LOG" ]] && grep -Eq 'journalctl[[:space:]].*(--since[[:space:]]+.*30[[:space:]]+min|--since[[:space:]]+"?30 minutes ago"?)' "$LOG" || { echo "❌ Q56 failed: journalctl --since for last 30 minutes not detected."; return 1; }
  echo "✅ Q56 PASSED."; return 0
}

# ===== Exercise Q57 =====
Q57_DESC="Configure the system so that journal logs are retained across system reboots."
check_Q57() {
  [[ -d /var/log/journal ]] || { echo "❌ Q57 failed: /var/log/journal missing."; return 1; }
  [[ -n "$(ls -A /var/log/journal 2>/dev/null)" ]] || { echo "❌ Q57 failed: /var/log/journal is empty. Run journalctl --flush or restart systemd-journald."; return 1; }
  echo "✅ Q57 PASSED."; return 0
}

# ===== Exercise Q58 =====
Q58_DESC="Configure the system to synchronize time with pool.ntp.org. Verify that time synchronization is functioning correctly."
check_Q58() {
  grep -RqsE '^(server|pool)[[:space:]]+pool\.ntp\.org' /etc/chrony.conf /etc/chrony.d/*.conf 2>/dev/null || { echo "❌ Q58 failed: pool.ntp.org not configured in chrony."; return 1; }
  systemctl is-enabled --quiet chronyd || { echo "❌ Q58 failed: chronyd is not enabled."; return 1; }
  systemctl is-active --quiet chronyd || { echo "❌ Q58 failed: chronyd is not running."; return 1; }
  chronyc tracking >/dev/null 2>&1 || { echo "❌ Q58 failed: chronyc tracking failed."; return 1; }
  echo "✅ Q58 PASSED."; return 0
}

# ===== Exercise Q59 =====
Q59_DESC="Configure the system to use server1.example.com as its NTP source. Verify that the configuration is active."
check_Q59() {
  grep -RqsE '^(server|pool)[[:space:]]+server1\.example\.com' /etc/chrony.conf /etc/chrony.d/*.conf 2>/dev/null || { echo "❌ Q59 failed: server1.example.com not configured in chrony."; return 1; }
  systemctl is-active --quiet chronyd || { echo "❌ Q59 failed: chronyd is not running."; return 1; }
  chronyc sources 2>/dev/null | grep -q 'server1.example.com' || { echo "❌ Q59 failed: chronyc sources does not show server1.example.com."; return 1; }
  echo "✅ Q59 PASSED."; return 0
}

# ===== Exercise Q60 =====
Q60_DESC="Configure SELinux so that the Apache web server is permitted to access user home directories. Ensure the configuration persists across reboots."
check_Q60() {
  command -v getsebool >/dev/null 2>&1 || { echo "❌ Q60 failed: getsebool not available."; return 1; }

  getsebool httpd_enable_homedirs 2>/dev/null | grep -Eq -- '--> (on|ativado)' || {
    echo "❌ Q60 failed: httpd_enable_homedirs is not on."
    return 1
  }

  LC_ALL=C semanage boolean -l 2>/dev/null | awk '$1=="httpd_enable_homedirs"{print}' | grep -Eq '\(on[[:space:]]*,[[:space:]]*on\)' || {
    echo "❌ Q60 failed: httpd_enable_homedirs not persistent."
    return 1
  }

  echo "✅ Q60 PASSED."
  return 0
}

# ===== Exercise Q61 =====
Q61_DESC="Create /webdata and configure SELinux so that Apache can permanently serve content from this directory."
check_Q61() {
  [[ -d /webdata ]] || { echo "❌ Q61 failed: /webdata directory missing."; return 1; }
  matchpathcon /webdata 2>/dev/null | grep -q 'httpd_sys_content_t' || { echo "❌ Q61 failed: persistent SELinux context for /webdata is not httpd_sys_content_t."; return 1; }
  ls -Zd /webdata 2>/dev/null | grep -q 'httpd_sys_content_t' || { echo "❌ Q61 failed: current SELinux context on /webdata is not httpd_sys_content_t."; return 1; }
  echo "✅ Q61 PASSED."; return 0
}

# ===== Exercise Q62 =====
Q62_DESC="Configure Apache to listen on TCP port 8080. Adjust SELinux settings as required to permit access to this port."
check_Q62() {
  grep -RqsE '^[[:space:]]*Listen[[:space:]]+8080' /etc/httpd/conf/httpd.conf /etc/httpd/conf.d/*.conf 2>/dev/null || { echo "❌ Q62 failed: Apache Listen 8080 not found."; return 1; }
  semanage port -l 2>/dev/null | awk '$1=="http_port_t"{print}' | grep -qw '8080' || { echo "❌ Q62 failed: TCP port 8080 not labeled as http_port_t."; return 1; }
  echo "✅ Q62 PASSED."; return 0
}

# ===== Exercise Q63 =====
Q63_DESC=" Create a Custom Service,the service must execute the script:

/root/backup.sh echo 'Backup completed'

Ensure the service definition is correctly recognized by systemd."

check_Q63() {
  local unit="/etc/systemd/system/backup.service"

  [[ -f "$unit" ]] || {
    echo "❌ Q63 failed: $unit missing."
    return 1
  }

  grep -Eq '^ExecStart=/root/backup\.sh' "$unit" || {
    echo "❌ Q63 failed: ExecStart is not /root/backup.sh."
    return 1
  }

  [[ -f /root/backup.sh ]] || {
    echo "❌ Q63 failed: /root/backup.sh missing."
    return 1
  }

  [[ -x /root/backup.sh ]] || {
    echo "❌ Q63 failed: /root/backup.sh is not executable."
    return 1
  }

  [[ -s /root/backup.sh ]] || {
    echo "❌ Q63 failed: /root/backup.sh is empty."
    return 1
  }

  head -n1 /root/backup.sh | grep -q '^#!' || {
    echo "❌ Q63 failed: /root/backup.sh missing shebang."
    return 1
  }

  systemctl cat backup.service >/dev/null 2>&1 || {
    echo "❌ Q63 failed: systemd does not recognize backup.service. Run systemctl daemon-reload."
    return 1
  }

  echo "✅ Q63 PASSED."
  return 0
}

# ===== Exercise Q64 =====
Q64_DESC="Configure backup.service so that it starts automatically during system boot. Verify that the service is enabled."
check_Q64() {
  systemctl is-enabled --quiet backup.service || { echo "❌ Q64 failed: backup.service is not enabled."; return 1; }
  echo "✅ Q64 PASSED."; return 0
}

# ===== Exercise Q65 =====
Q65_DESC="An existing XFS filesystem is mounted on /mnt/xfs_lv. Increase the size of the filesystem by 300 MB without unmounting it and ensure the additional capacity is available immediately."

check_Q65() {

  local lvpath="/dev/xfs_vg/xfs_lv"
  local mp="/mnt/xfs_lv"

  # LV exists
  sudo -n lvs --noheadings "$lvpath" >/dev/null 2>&1 || {
    echo "❌ Q65 failed: $lvpath not found."
    return 1
  }

  # Mount point exists
  [[ -d "$mp" ]] || {
    echo "❌ Q65 failed: $mp not found."
    return 1
  }

  # Filesystem mounted
  findmnt -n "$mp" >/dev/null 2>&1 || {
    echo "❌ Q65 failed: $mp is not mounted."
    return 1
  }

  # Must be XFS
  [[ "$(findmnt -n "$mp" -o FSTYPE)" == "xfs" ]] || {
    echo "❌ Q65 failed: filesystem is not XFS."
    return 1
  }

  # LV must be at least 600M (initial size = 400M)
  local lvsz n

  lvsz="$(sudo -n lvs --noheadings --units m -o lv_size "$lvpath" \
      2>/dev/null | tr -d ' ' | tr 'A-Z' 'a-z')"

  n="$(echo "$lvsz" | sed -n 's/^\([0-9]\+\).*/\1/p')"

  [[ -n "$n" ]] && (( n >= 600 )) || {
    echo "❌ Q65 failed: LV size is $lvsz; expected at least 600M."
    return 1
  }

  # Filesystem must also have been grown
local fssz

fssz="$(df -BM "$mp" | awk 'NR==2 {gsub("M","",$2); print $2}')"

[[ -n "$fssz" ]] && (( fssz >= 500 )) || {
  echo "❌ Q65 failed: XFS filesystem size is ${fssz}M; expected at least 500M after growth."
  return 1
}

  echo "✅ Q65 PASSED."
  return 0
}

# ===== Exercise Q66 =====
Q66_DESC="Configure the firewall to permanently allow access to TCP port 8080. Apply the configuration immediately."
check_Q66() {
  systemctl is-active --quiet firewalld || { echo "❌ Q66 failed: firewalld not running."; return 1; }
  firewall-cmd --list-ports | grep -qw '8080/tcp' || { echo "❌ Q66 failed: 8080/tcp not active."; return 1; }
  firewall-cmd --permanent --list-ports | grep -qw '8080/tcp' || { echo "❌ Q66 failed: 8080/tcp not permanent."; return 1; }
  echo "✅ Q66 PASSED."; return 0
}

# ===== Exercise Q67 =====
Q67_DESC="Configure the firewall to permanently allow access to the NFS service. Verify that the service is permitted through the firewall."
check_Q67() {
  systemctl is-active --quiet firewalld || { echo "❌ Q67 failed: firewalld not running."; return 1; }
  firewall-cmd --list-services | grep -qw 'nfs' || { echo "❌ Q67 failed: nfs service not active."; return 1; }
  firewall-cmd --permanent --list-services | grep -qw 'nfs' || { echo "❌ Q67 failed: nfs service not permanent."; return 1; }
  echo "✅ Q67 PASSED."; return 0
}

# ===== Exercise Q68 =====
Q68_DESC="Configure a firewall rich rule that permits SSH access only from 192.168.100.0/24. Apply the configuration immediately."
check_Q68() {
  local rule='rule family="ipv4" source address="192.168.100.0/24" service name="ssh" accept'
  systemctl is-active --quiet firewalld || { echo "❌ Q68 failed: firewalld not running."; return 1; }
  firewall-cmd --list-rich-rules | grep -Fq "$rule" || { echo "❌ Q68 failed: rich rule not active."; return 1; }
  firewall-cmd --permanent --list-rich-rules | grep -Fq "$rule" || { echo "❌ Q68 failed: rich rule not permanent."; return 1; }
  echo "✅ Q68 PASSED."; return 0
}

# ===== Exercise Q69 =====
Q69_DESC="Create an executable shell script /root/check-user.sh that receives a username argument and displays 'User Exists' if the user exists, otherwise 'User Not Found'."
check_Q69() {
  local script="/root/check-user.sh"
  [[ -f "$script" && -x "$script" ]] || { echo "❌ Q69 failed: $script missing or not executable."; return 1; }
  local existing="root" missing="rhcsa_missing_user_987" out1 out2
  out1="$(bash "$script" "$existing" 2>/dev/null | sed 's/[[:space:]]\+$//')"
  out2="$(bash "$script" "$missing" 2>/dev/null | sed 's/[[:space:]]\+$//')"
  [[ "$out1" == "User Exists" ]] || { echo "❌ Q69 failed: existing user output is '$out1'."; return 1; }
  [[ "$out2" == "User Not Found" ]] || { echo "❌ Q69 failed: missing user output is '$out2'."; return 1; }
  echo "✅ Q69 PASSED."; return 0
}

# ===== Exercise Q70 =====
Q70_DESC="Create an executable shell script /root/check-files.sh that accepts multiple filenames as arguments and displays only the filenames that currently exist on the system."
check_Q70() {
  local script="/root/check-files.sh"
  [[ -f "$script" && -x "$script" ]] || { echo "❌ Q70 failed: $script missing or not executable."; return 1; }
  sudo touch /tmp/Q70_exists_a /tmp/Q70_exists_b
  sudo rm -f /tmp/Q70_missing_c
  local out
  out="$(bash "$script" /tmp/Q70_exists_a /tmp/Q70_missing_c /tmp/Q70_exists_b 2>/dev/null)"
  echo "$out" | grep -Fxq '/tmp/Q70_exists_a' || { echo "❌ Q70 failed: existing file /tmp/Q70_exists_a not printed."; return 1; }
  echo "$out" | grep -Fxq '/tmp/Q70_exists_b' || { echo "❌ Q70 failed: existing file /tmp/Q70_exists_b not printed."; return 1; }
  if echo "$out" | grep -Fxq '/tmp/Q70_missing_c'; then echo "❌ Q70 failed: missing file was printed."; return 1; fi
  echo "✅ Q70 PASSED."; return 0
}

# ===== Exercise Q71 =====
Q71_DESC="Configure a file /secure/passwd-tool so that it is owned by root:root and has the appropriate permissions to allow execution with the owner's privileges."

check_Q71() {
  local file="/secure/passwd-tool"

  if [[ ! -f "$file" ]]; then
    echo "❌ Q71 failed: $file does not exist."
    return 1
  fi

  local owner group mode
  owner="$(stat -c '%U' "$file" 2>/dev/null || true)"
  group="$(stat -c '%G' "$file" 2>/dev/null || true)"
  mode="$(stat -c '%a' "$file" 2>/dev/null || true)"

  if [[ "$owner" != "root" ]]; then
    echo "❌ Q71 failed: owner is '$owner' (expected root)."
    return 1
  fi

  if [[ "$group" != "root" ]]; then
    echo "❌ Q71 failed: group is '$group' (expected root)."
    return 1
  fi

  if [[ "$mode" != "4755" ]]; then
    echo "❌ Q71 failed: permissions are '$mode' (expected 4755)."
    return 1
  fi

  echo "✅ Q71 PASSED: SUID file configured correctly."
  return 0
}


# ===== Exercise Q72 =====
Q72_DESC="Configure the directory /shared-devs so that members of the devs group can collaborate and newly created files retain the correct group ownership."

check_Q72() {
  local dir="/shared-devs"

  if [[ ! -d "$dir" ]]; then
    echo "❌ Q72 failed: $dir does not exist."
    return 1
  fi

  if ! getent group devs >/dev/null; then
    echo "❌ Q72 failed: group devs does not exist."
    return 1
  fi

  local owner group mode
  owner="$(stat -c '%U' "$dir" 2>/dev/null || true)"
  group="$(stat -c '%G' "$dir" 2>/dev/null || true)"
  mode="$(stat -c '%a' "$dir" 2>/dev/null || true)"

  if [[ "$owner" != "root" ]]; then
    echo "❌ Q72 failed: owner is '$owner' (expected root)."
    return 1
  fi

  if [[ "$group" != "devs" ]]; then
    echo "❌ Q72 failed: group is '$group' (expected devs)."
    return 1
  fi

  if [[ "$mode" != "2770" ]]; then
    echo "❌ Q72 failed: permissions are '$mode' (expected 2770)."
    return 1
  fi

  echo "✅ Q72 PASSED: SGID shared directory configured correctly."
  return 0
}


# ===== Exercise Q73 =====
Q73_DESC="Configure the directory /public-share to allow all users to create files while preventing users from deleting files owned by others."

check_Q73() {
  local dir="/public-share"

  if [[ ! -d "$dir" ]]; then
    echo "❌ Q73 failed: $dir does not exist."
    return 1
  fi

  local mode
  mode="$(stat -c '%a' "$dir" 2>/dev/null || true)"

  if [[ "$mode" != "1777" ]]; then
    echo "❌ Q73 failed: permissions are '$mode' (expected 1777)."
    return 1
  fi

  echo "✅ Q73 PASSED: sticky bit directory configured correctly."
  return 0
}


# ===== Exercise Q74 =====
Q74_DESC="Identify all regular files that execute with the file owner's privileges and save their absolute paths to /root/suid-files.txt."

check_Q74() {
  local output="/root/suid-files.txt"
  local sentinel="/var/tmp/rhcsa-special-perms/suid-test"

  if [[ ! -f "$output" ]]; then
    echo "❌ Q74 failed: $output does not exist."
    return 1
  fi

  if [[ ! -s "$output" ]]; then
    echo "❌ Q74 failed: $output is empty."
    return 1
  fi

  if ! grep -Fxq "$sentinel" "$output"; then
    echo "❌ Q74 failed: known SUID test file is missing from the results."
    echo "    Missing: $sentinel"
    return 1
  fi

  local path
  local bad=0

  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "$path" ]] && continue

    if [[ "$path" != /* ]]; then
      echo "❌ Q74 failed: path is not absolute: $path"
      bad=1
      continue
    fi

    if [[ ! -f "$path" ]]; then
      echo "❌ Q74 failed: listed path is not a regular file: $path"
      bad=1
      continue
    fi

    if ! find "$path" -maxdepth 0 -type f -perm -4000 -print -quit \
      2>/dev/null | grep -q .; then
      echo "❌ Q74 failed: listed file does not have SUID enabled: $path"
      bad=1
    fi
  done < "$output"

  if [[ "$bad" -ne 0 ]]; then
    return 1
  fi

  echo "✅ Q74 PASSED: SUID file list is valid."
  return 0
}


# ===== Exercise Q75 =====
Q75_DESC="Identify all regular files that execute with the file group's privileges and save their absolute paths to /root/sgid-files.txt."

check_Q75() {
  local output="/root/sgid-files.txt"
  local sentinel="/var/tmp/rhcsa-special-perms/sgid-test"

  if [[ ! -f "$output" ]]; then
    echo "❌ Q75 failed: $output does not exist."
    return 1
  fi

  if [[ ! -s "$output" ]]; then
    echo "❌ Q75 failed: $output is empty."
    return 1
  fi

  if ! grep -Fxq "$sentinel" "$output"; then
    echo "❌ Q75 failed: known SGID test file is missing from the results."
    echo "    Missing: $sentinel"
    return 1
  fi

  local path
  local bad=0

  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "$path" ]] && continue

    if [[ "$path" != /* ]]; then
      echo "❌ Q75 failed: path is not absolute: $path"
      bad=1
      continue
    fi

    if [[ ! -f "$path" ]]; then
      echo "❌ Q75 failed: listed path is not a regular file: $path"
      bad=1
      continue
    fi

    if ! find "$path" -maxdepth 0 -type f -perm -2000 -print -quit \
      2>/dev/null | grep -q .; then
      echo "❌ Q75 failed: listed file does not have SGID enabled: $path"
      bad=1
    fi
  done < "$output"

  if [[ "$bad" -ne 0 ]]; then
    return 1
  fi

  echo "✅ Q75 PASSED: SGID file list is valid."
  return 0
}


# ===== Exercise Q76 =====
Q76_DESC="Copy /etc/fstab to /acl-lab/fstab. Configure the copied file so that the owner has read and write access, the owning group has read-only access, user adam has read and write access, user maryam has no access, and all other users have read-only access."

check_Q76() {
  local file="/acl-lab/fstab"

  if [[ ! -f "$file" ]]; then
    echo "❌ Q76 failed: $file does not exist."
    return 1
  fi

  if ! command -v getfacl >/dev/null 2>&1; then
    echo "❌ Q76 failed: getfacl command is not installed."
    return 1
  fi

  local acl
  acl="$(getfacl -cp "$file" 2>/dev/null || true)"

  if ! grep -Fxq 'user::rw-' <<< "$acl"; then
    echo "❌ Q76 failed: owner permissions must be rw-."
    return 1
  fi

  if ! grep -Fxq 'user:adam:rw-' <<< "$acl"; then
    echo "❌ Q76 failed: ACL for adam must be rw-."
    return 1
  fi

  if ! grep -Fxq 'user:maryam:---' <<< "$acl"; then
    echo "❌ Q76 failed: ACL for maryam must be ---."
    return 1
  fi

  if ! grep -Fxq 'group::r--' <<< "$acl"; then
    echo "❌ Q76 failed: owning group permissions must be r--."
    return 1
  fi

  if ! grep -Fxq 'mask::rw-' <<< "$acl"; then
    echo "❌ Q76 failed: ACL mask must allow rw-."
    return 1
  fi

  if ! grep -Fxq 'other::r--' <<< "$acl"; then
    echo "❌ Q76 failed: other permissions must be r--."
    return 1
  fi

  local mode
  mode="$(stat -c '%a' "$file")"

  if (( 8#$mode & 0111 )); then
    echo "❌ Q76 failed: file must not be executable."
    return 1
  fi

  echo "✅ Q76 PASSED: access permissions configured correctly."
  return 0
}


# ===== Exercise Q77 =====
Q77_DESC="Create the file /project/report.txt. Configure it so that the owner has read and write access, the owning group has read-only access, user jacob has read and write access, and all other users have no access."
check_Q77() {
  local file="/project/report.txt"

  if [[ ! -f "$file" ]]; then
    echo "❌ Q77 failed: $file does not exist."
    return 1
  fi

  local acl
  acl="$(getfacl -cp "$file" 2>/dev/null || true)"

  if ! grep -Fxq 'user::rw-' <<< "$acl"; then
    echo "❌ Q77 failed: owner permissions must be rw-."
    return 1
  fi

  if ! grep -Fxq 'user:jacob:rw-' <<< "$acl"; then
    echo "❌ Q77 failed: ACL for jacob must be rw-."
    return 1
  fi

  if ! grep -Fxq 'group::r--' <<< "$acl"; then
    echo "❌ Q77 failed: owning group permissions must be r--."
    return 1
  fi

  if ! grep -Fxq 'mask::rw-' <<< "$acl"; then
    echo "❌ Q77 failed: ACL mask must allow rw-."
    return 1
  fi

  if ! grep -Fxq 'other::---' <<< "$acl"; then
    echo "❌ Q77 failed: other users must have no access."
    return 1
  fi

  echo "✅ Q77 PASSED: ACL for jacob configured correctly."
  return 0
}


# ===== Exercise Q78 =====
Q78_DESC="Create the directory /projects and configure it so that user adam can read, write, and access the directory. Ensure that new files created inside /projects automatically grant adam read and write access, and new directories automatically grant adam read, write, and traverse access."

check_Q78() {
  local dir="/projects"
  local testfile="$dir/.q78-test-file-$$"
  local testdir="$dir/.q78-test-dir-$$"
  local acl

  if [[ ! -d "$dir" ]]; then
    echo "❌ Q78 failed: $dir does not exist."
    return 1
  fi

  if ! id adam &>/dev/null; then
    echo "❌ Q78 failed: user adam does not exist."
    return 1
  fi

  if ! command -v getfacl &>/dev/null; then
    echo "❌ Q78 failed: getfacl command is not installed."
    return 1
  fi

  if ! command -v runuser &>/dev/null; then
    echo "❌ Q78 failed: runuser command is not available."
    return 1
  fi

  acl="$(getfacl -cpE "$dir" 2>/dev/null || true)"

  # Adam must be able to use the existing /projects directory
  if ! grep -Fxq 'user:adam:rwx' <<< "$acl"; then
    echo "❌ Q78 failed: adam must have rwx access to $dir."
    return 1
  fi

  # New objects must inherit Adam's ACL entry
  if ! grep -Fxq 'default:user:adam:rwx' <<< "$acl"; then
    echo "❌ Q78 failed: inherited permissions for adam are not configured."
    return 1
  fi

  # The default ACL mask must permit rwx
  if ! grep -Fxq 'default:mask::rwx' <<< "$acl"; then
    echo "❌ Q78 failed: the default ACL mask must permit rwx."
    return 1
  fi

  # Create objects using normal file and directory creation modes
  if ! touch "$testfile"; then
    echo "❌ Q78 failed: could not create a test file in $dir."
    return 1
  fi

  if ! mkdir "$testdir"; then
    rm -f "$testfile"
    echo "❌ Q78 failed: could not create a test directory in $dir."
    return 1
  fi

  # Verify that a named ACL entry was inherited
  if ! getfacl -cpE "$testfile" 2>/dev/null |
       grep -Eq '^user:adam:rw[x-]$'; then
    rm -f "$testfile"
    rmdir "$testdir"
    echo "❌ Q78 failed: new files do not inherit an ACL entry for adam."
    return 1
  fi

  if ! getfacl -cpE "$testdir" 2>/dev/null |
       grep -Fxq 'user:adam:rwx'; then
    rm -f "$testfile"
    rmdir "$testdir"
    echo "❌ Q78 failed: new directories do not inherit rwx access for adam."
    return 1
  fi

  # Test Adam's effective access to the new file
  if ! runuser -u adam -- test -r "$testfile" ||
     ! runuser -u adam -- test -w "$testfile"; then
    rm -f "$testfile"
    rmdir "$testdir"
    echo "❌ Q78 failed: adam does not have effective read/write access to new files."
    return 1
  fi

  # Regular files must not become executable
  if runuser -u adam -- test -x "$testfile"; then
    rm -f "$testfile"
    rmdir "$testdir"
    echo "❌ Q78 failed: new regular files must not be executable by adam."
    return 1
  fi

  # Test Adam's effective access to the new directory
  if ! runuser -u adam -- test -r "$testdir" ||
     ! runuser -u adam -- test -w "$testdir" ||
     ! runuser -u adam -- test -x "$testdir"; then
    rm -f "$testfile"
    rmdir "$testdir"
    echo "❌ Q78 failed: adam does not have effective rwx access to new directories."
    return 1
  fi

  rm -f "$testfile"
  rmdir "$testdir"

  echo "✅ Q78 PASSED: inherited access permissions configured correctly."
  return 0
}

# ===== Exercise Q79 =====
Q79_DESC="Create the directory /shared-reports and configure it so that members of the finance group have read, write, and traverse access. Ensure that new files automatically grant the finance group read and write access, new directories grant read, write, and traverse access, and all other users receive no access."

check_Q79() {
  local dir="/shared-reports"
  local testfile="$dir/.q79-test-file-$$"
  local testdir="$dir/.q79-test-dir-$$"
  local acl
  local inherited_acl

  cleanup_Q79() {
    rm -f "$testfile"
    rm -rf "$testdir"
  }

  if [[ ! -d "$dir" ]]; then
    echo "❌ Q79 failed: $dir does not exist."
    return 1
  fi

  if ! getent group finance &>/dev/null; then
    echo "❌ Q79 failed: group finance does not exist."
    return 1
  fi

  if ! command -v getfacl &>/dev/null; then
    echo "❌ Q79 failed: getfacl command is not installed."
    return 1
  fi

  acl="$(getfacl -cpE "$dir" 2>/dev/null || true)"

  if ! grep -Fxq 'group:finance:rwx' <<< "$acl"; then
    echo "❌ Q79 failed: group finance must have rwx access to $dir."
    return 1
  fi

  if ! grep -Fxq 'other::---' <<< "$acl"; then
    echo "❌ Q79 failed: other users must have no access to $dir."
    return 1
  fi

  if ! grep -Fxq 'default:group:finance:rwx' <<< "$acl"; then
    echo "❌ Q79 failed: inherited permissions for group finance are not configured."
    return 1
  fi

  if ! grep -Fxq 'default:mask::rwx' <<< "$acl"; then
    echo "❌ Q79 failed: default ACL mask must permit rwx."
    return 1
  fi

  if ! grep -Fxq 'default:other::---' <<< "$acl"; then
    echo "❌ Q79 failed: inherited permissions for other users must be disabled."
    return 1
  fi

  if ! touch "$testfile"; then
    echo "❌ Q79 failed: could not create a test file in $dir."
    return 1
  fi

  if ! mkdir "$testdir"; then
    cleanup_Q79
    echo "❌ Q79 failed: could not create a test directory in $dir."
    return 1
  fi

  inherited_acl="$(getfacl -cpE "$testfile" 2>/dev/null || true)"

  if ! grep -Fxq 'group:finance:rwx' <<< "$inherited_acl"; then
    cleanup_Q79
    echo "❌ Q79 failed: new files do not inherit the finance ACL entry."
    return 1
  fi

  if ! grep -Fxq 'mask::rw-' <<< "$inherited_acl"; then
    cleanup_Q79
    echo "❌ Q79 failed: finance does not have effective read/write access to new files."
    return 1
  fi

  if ! grep -Fxq 'other::---' <<< "$inherited_acl"; then
    cleanup_Q79
    echo "❌ Q79 failed: new files grant access to other users."
    return 1
  fi

  inherited_acl="$(getfacl -cpE "$testdir" 2>/dev/null || true)"

  if ! grep -Fxq 'group:finance:rwx' <<< "$inherited_acl"; then
    cleanup_Q79
    echo "❌ Q79 failed: new directories do not inherit finance rwx permissions."
    return 1
  fi

  if ! grep -Fxq 'mask::rwx' <<< "$inherited_acl"; then
    cleanup_Q79
    echo "❌ Q79 failed: finance does not have effective rwx access to new directories."
    return 1
  fi

  if ! grep -Fxq 'other::---' <<< "$inherited_acl"; then
    cleanup_Q79
    echo "❌ Q79 failed: new directories grant access to other users."
    return 1
  fi

  cleanup_Q79

  echo "✅ Q79 PASSED: inherited group permissions configured correctly."
  return 0
}

# ===== Exercise Q80 =====
Q80_DESC="Back up the ACL configuration of /projects to /root/projects.acl."

check_Q80() {
  local source="/projects"
  local backup="/root/projects.acl"

  if [[ ! -d "$source" ]]; then
    echo "❌ Q80 failed: source directory $source does not exist."
    return 1
  fi

  if [[ ! -f "$backup" ]]; then
    echo "❌ Q80 failed: $backup does not exist."
    return 1
  fi

  if [[ ! -s "$backup" ]]; then
    echo "❌ Q80 failed: $backup is empty."
    return 1
  fi

  if ! grep -Eq '^# file: /?projects$' "$backup"; then
    echo "❌ Q80 failed: backup does not contain an ACL record for /projects."
    return 1
  fi

  if ! grep -Fxq 'default:user:adam:rwx' "$backup"; then
    echo "❌ Q80 failed: backup does not contain the default ACL for adam."
    return 1
  fi

  echo "✅ Q80 PASSED: ACL backup created correctly."
  return 0
}

# ===== Exercise Q81 =====
Q81_DESC="Ensure that user student runs /usr/bin/logger \"daily backup\" every day at 01:30."

check_Q81() {
  local user="student"

  if ! getent passwd "$user" >/dev/null; then
    echo "❌ Q81 failed: user $user does not exist."
    return 1
  fi

  if ! systemctl is-active --quiet crond; then
    echo "❌ Q81 failed: crond is not running."
    return 1
  fi

  local crontab
  crontab="$(crontab -u "$user" -l 2>/dev/null || true)"

  if [[ -z "$crontab" ]]; then
    echo "❌ Q81 failed: no crontab found for user $user."
    return 1
  fi

  if ! grep -Eq \
    '^[[:space:]]*30[[:space:]]+1[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+(/usr/bin/)?logger[[:space:]]+"?daily backup"?[[:space:]]*$' \
    <<< "$crontab"; then
    echo "❌ Q81 failed: expected daily cron job at 01:30 was not found."
    return 1
  fi

  echo "✅ Q81 PASSED: student cron job configured correctly."
  return 0
}


# ===== Exercise Q82 =====
Q82_DESC="Configure a root cron job that executes /usr/bin/touch /root/cron-success every Sunday at 02:00."

check_Q82() {
  if ! systemctl is-active --quiet crond; then
    echo "❌ Q82 failed: crond is not running."
    return 1
  fi

  local crontab
  crontab="$(crontab -u root -l 2>/dev/null || true)"

  if [[ -z "$crontab" ]]; then
    echo "❌ Q82 failed: no root crontab was found."
    return 1
  fi

  # Accept Sunday as 0 or 7.
  if ! grep -Eq \
    '^[[:space:]]*0[[:space:]]+2[[:space:]]+\*[[:space:]]+\*[[:space:]]+(0|7)[[:space:]]+(/usr/bin/)?touch[[:space:]]+/root/cron-success[[:space:]]*$' \
    <<< "$crontab"; then
    echo "❌ Q82 failed: expected Sunday cron job at 02:00 was not found."
    return 1
  fi

  echo "✅ Q82 PASSED: root cron job configured correctly."
  return 0
}


# ===== Exercise Q83 =====
Q83_DESC="Configure a cron job that appends the current date and time to /var/log/cron-test.log every five minutes."

check_Q83() {
  if ! systemctl is-active --quiet crond; then
    echo "❌ Q83 failed: crond is not running."
    return 1
  fi

  if ! systemctl is-enabled --quiet crond; then
    echo "❌ Q83 failed: crond is not enabled at boot."
    return 1
  fi

  local crontab
  crontab="$(crontab -u root -l 2>/dev/null || true)"

  if [[ -z "$crontab" ]]; then
    echo "❌ Q83 failed: no root crontab was found."
    return 1
  fi

  if ! grep -Eq \
    '^[[:space:]]*\*/5[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+(/usr/bin/)?date[[:space:]]*>>[[:space:]]*/var/log/cron-test\.log[[:space:]]*$' \
    <<< "$crontab"; then
    echo "❌ Q83 failed: expected job running every five minutes was not found."
    return 1
  fi

  echo "✅ Q83 PASSED: five-minute cron job configured correctly."
  return 0
}


# ===== Exercise Q84 =====
Q84_DESC="Ensure that user maryam can use cron while user jacob cannot."

check_Q84() {
  if ! getent passwd maryam >/dev/null; then
    echo "❌ Q84 failed: user maryam does not exist."
    return 1
  fi

  if ! getent passwd jacob >/dev/null; then
    echo "❌ Q84 failed: user jacob does not exist."
    return 1
  fi

  if [[ ! -f /etc/cron.allow ]]; then
    echo "❌ Q84 failed: /etc/cron.allow does not exist."
    return 1
  fi

  if ! grep -Eq '^[[:space:]]*maryam[[:space:]]*$' /etc/cron.allow; then
    echo "❌ Q84 failed: maryam is not listed in /etc/cron.allow."
    return 1
  fi

  if grep -Eq '^[[:space:]]*jacob[[:space:]]*$' /etc/cron.allow; then
    echo "❌ Q84 failed: jacob must not be listed in /etc/cron.allow."
    return 1
  fi

  # cron.allow takes precedence when it exists.
  # cron.deny is checked as an additional explicit requirement.
  if [[ ! -f /etc/cron.deny ]]; then
    echo "❌ Q84 failed: /etc/cron.deny does not exist."
    return 1
  fi

  if ! grep -Eq '^[[:space:]]*jacob[[:space:]]*$' /etc/cron.deny; then
    echo "❌ Q84 failed: jacob is not listed in /etc/cron.deny."
    return 1
  fi

  local allow_owner allow_group allow_mode
  allow_owner="$(stat -c '%U' /etc/cron.allow)"
  allow_group="$(stat -c '%G' /etc/cron.allow)"
  allow_mode="$(stat -c '%a' /etc/cron.allow)"

  if [[ "$allow_owner" != "root" || "$allow_group" != "root" ]]; then
    echo "❌ Q84 failed: /etc/cron.allow must be owned by root:root."
    return 1
  fi

  if [[ "$allow_mode" != "600" ]]; then
    echo "❌ Q84 failed: /etc/cron.allow permissions are $allow_mode; expected 600."
    return 1
  fi

  echo "✅ Q84 PASSED: cron access control configured correctly."
  return 0
}


# ===== Exercise Q85 =====
Q85_DESC="Create hello.service and hello.timer. The service must log \"hello folks\" and the timer must run every day at 03:00."

check_Q85() {
  local service="/etc/systemd/system/hello.service"
  local timer="/etc/systemd/system/hello.timer"

  if [[ ! -f "$service" ]]; then
    echo "❌ Q85 failed: $service does not exist."
    return 1
  fi

  if [[ ! -f "$timer" ]]; then
    echo "❌ Q85 failed: $timer does not exist."
    return 1
  fi

  if ! systemd-analyze verify "$service" "$timer" >/dev/null 2>&1; then
    echo "❌ Q85 failed: one or more unit files contain invalid syntax."
    systemd-analyze verify "$service" "$timer" 2>&1 | head -10
    return 1
  fi

  if ! grep -Eq \
    '^ExecStart=/usr/bin/logger[[:space:]]+"?hello folks"?[[:space:]]*$' \
    "$service"; then
    echo "❌ Q85 failed: hello.service has an incorrect ExecStart."
    return 1
  fi

  if ! grep -Eq \
    '^OnCalendar=(\*-\*-\*[[:space:]]+)?03:00(:00)?$' \
    "$timer"; then
    echo "❌ Q85 failed: hello.timer is not scheduled daily at 03:00."
    return 1
  fi

  if ! grep -Eq '^Persistent=(true|yes|1)$' "$timer"; then
    echo "❌ Q85 failed: Persistent=true is not configured."
    return 1
  fi

  if ! systemctl is-enabled --quiet hello.timer; then
    echo "❌ Q85 failed: hello.timer is not enabled."
    return 1
  fi

  if ! systemctl is-active --quiet hello.timer; then
    echo "❌ Q85 failed: hello.timer is not active."
    return 1
  fi

  echo "✅ Q85 PASSED: daily systemd timer configured correctly."
  return 0
}


# ===== Exercise Q86 =====
Q86_DESC="Create timer-test.service and timer-test.timer. The service must append the date to /var/log/timer-test.log and run every ten minutes."

check_Q86() {
  local service="/etc/systemd/system/timer-test.service"
  local timer="/etc/systemd/system/timer-test.timer"

  if [[ ! -f "$service" ]]; then
    echo "❌ Q86 failed: $service does not exist."
    return 1
  fi

  if [[ ! -f "$timer" ]]; then
    echo "❌ Q86 failed: $timer does not exist."
    return 1
  fi

  if ! systemd-analyze verify "$service" "$timer" >/dev/null 2>&1; then
    echo "❌ Q86 failed: one or more unit files contain invalid syntax."
    systemd-analyze verify "$service" "$timer" 2>&1 | head -10
    return 1
  fi

  local execstart
  execstart="$(systemctl show timer-test.service \
    -p ExecStart --value 2>/dev/null || true)"

  if [[ "$execstart" != *"/usr/bin/date"* ||
        "$execstart" != *"/var/log/timer-test.log"* ]]; then
    echo "❌ Q86 failed: timer-test.service does not append date output to the expected file."
    return 1
  fi

  if ! grep -Eq '^OnUnitActiveSec=10min$' "$timer"; then
    echo "❌ Q86 failed: OnUnitActiveSec=10min was not found."
    return 1
  fi

  if ! systemctl is-enabled --quiet timer-test.timer; then
    echo "❌ Q86 failed: timer-test.timer is not enabled."
    return 1
  fi

  if ! systemctl is-active --quiet timer-test.timer; then
    echo "❌ Q86 failed: timer-test.timer is not active."
    return 1
  fi

  # Execute the service directly to validate its behavior.
  local before after
  before="$(stat -c '%Y' /var/log/timer-test.log 2>/dev/null || echo 0)"

  if ! systemctl start timer-test.service >/dev/null 2>&1; then
    echo "❌ Q86 failed: timer-test.service could not be started."
    return 1
  fi

  after="$(stat -c '%Y' /var/log/timer-test.log 2>/dev/null || echo 0)"

  if [[ ! -s /var/log/timer-test.log ]]; then
    echo "❌ Q86 failed: /var/log/timer-test.log was not created or is empty."
    return 1
  fi

  if (( after < before )); then
    echo "❌ Q86 failed: the log file was not updated."
    return 1
  fi

  echo "✅ Q86 PASSED: ten-minute systemd timer configured correctly."
  return 0
}


# ===== Exercise Q87 =====
Q87_DESC="For user chisha, create a user service named hello-user.service that runs /usr/bin/logger \"user timer\". Create and enable hello-user.timer so that the service runs Monday through Friday at 02:00. Configure the user's systemd manager to remain active while chisha is logged out."
check_Q87() {
  local user="chisha"
  local home
  local service
  local timer
  local wants

  if ! getent passwd "$user" >/dev/null; then
    echo "❌ Q87 failed: user $user does not exist."
    return 1
  fi

  home="$(getent passwd "$user" | cut -d: -f6)"
  service="$home/.config/systemd/user/hello-user.service"
  timer="$home/.config/systemd/user/hello-user.timer"
  wants="$home/.config/systemd/user/timers.target.wants/hello-user.timer"

  if [[ ! -f "$service" ]]; then
    echo "❌ Q87 failed: $service does not exist."
    return 1
  fi

  if [[ ! -f "$timer" ]]; then
    echo "❌ Q87 failed: $timer does not exist."
    return 1
  fi

  if [[ "$(stat -c '%U' "$service")" != "$user" ||
        "$(stat -c '%U' "$timer")" != "$user" ]]; then
    echo "❌ Q87 failed: user unit files must be owned by chisha."
    return 1
  fi

  if ! grep -Eq \
    '^ExecStart=/usr/bin/logger[[:space:]]+"?user timer"?[[:space:]]*$' \
    "$service"; then
    echo "❌ Q87 failed: hello-user.service has an incorrect ExecStart."
    return 1
  fi

  if ! grep -Eq \
    '^OnCalendar=Mon\.\.Fri[[:space:]]+\*-\*-\*[[:space:]]+02:00(:00)?$' \
    "$timer"; then
    echo "❌ Q87 failed: user timer schedule is incorrect."
    return 1
  fi

  if ! grep -Eq '^Persistent=(true|yes|1)$' "$timer"; then
    echo "❌ Q87 failed: Persistent=true is not configured."
    return 1
  fi

  if [[ ! -L "$wants" ]]; then
    echo "❌ Q87 failed: hello-user.timer is not enabled for user chisha."
    return 1
  fi

  if [[ "$(readlink -f "$wants" 2>/dev/null)" != "$timer" ]]; then
    echo "❌ Q87 failed: enabled timer symlink points to the wrong unit."
    return 1
  fi

  if ! loginctl show-user "$user" -p Linger --value 2>/dev/null |
    grep -qx 'yes'; then
    echo "❌ Q87 failed: linger is not enabled for user chisha."
    return 1
  fi

  # Verify user manager state when a runtime directory is available.
  local uid runtime
  uid="$(id -u "$user")"
  runtime="/run/user/$uid"

  if [[ -d "$runtime" ]]; then
    if ! runuser -u "$user" -- env \
      XDG_RUNTIME_DIR="$runtime" \
      systemctl --user is-active --quiet hello-user.timer; then
      echo "❌ Q87 failed: hello-user.timer is not active."
      return 1
    fi
  fi

  echo "✅ Q87 PASSED: user systemd timer configured correctly."
  return 0
}

# ===== Exercise Q88 =====
Q88_DESC="Determine whether the httpd package is installed and save its package name, version, release, and architecture to /root/httpd-version.txt."

check_Q88() {
  local package="httpd"
  local output="/root/httpd-version.txt"
  local expected

  if ! rpm -q "$package" >/dev/null 2>&1; then
    echo "❌ Q88 failed: package $package is not installed."
    return 1
  fi

  if [[ ! -f "$output" ]]; then
    echo "❌ Q88 failed: $output does not exist."
    return 1
  fi

  if [[ ! -s "$output" ]]; then
    echo "❌ Q88 failed: $output is empty."
    return 1
  fi

  expected="$(rpm -q \
    --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' \
    "$package" 2>/dev/null)"

  if ! grep -Fxq "$expected" "$output"; then
    echo "❌ Q88 failed: $output does not contain the expected package information."
    echo "    Expected: $expected"
    return 1
  fi

  echo "✅ Q88 PASSED: httpd package information saved correctly."
  return 0
}


# ===== Exercise Q89 =====
Q89_DESC="Determine which installed RPM package owns /usr/bin/ssh and save the package name to /root/ssh-package.txt."

check_Q89() {
  local file="/usr/bin/ssh"
  local output="/root/ssh-package.txt"
  local expected

  if [[ ! -e "$file" ]]; then
    echo "❌ Q89 failed: $file does not exist."
    return 1
  fi

  if [[ ! -f "$output" ]]; then
    echo "❌ Q89 failed: $output does not exist."
    return 1
  fi

  if [[ ! -s "$output" ]]; then
    echo "❌ Q89 failed: $output is empty."
    return 1
  fi

  expected="$(rpm -qf "$file" 2>/dev/null || true)"

  if [[ -z "$expected" ]]; then
    echo "❌ Q89 failed: RPM database could not identify the owner of $file."
    return 1
  fi

  if ! grep -Fxq "$expected" "$output"; then
    echo "❌ Q89 failed: incorrect package saved to $output."
    echo "    Expected: $expected"
    return 1
  fi

  echo "✅ Q89 PASSED: owning RPM package identified correctly."
  return 0
}


# ===== Exercise Q90 =====
Q90_DESC="Install the local RPM package /root/packages/demo-package.rpm and verify that it is installed."

check_Q90() {
  local rpm_file="/root/packages/demo-package.rpm"
  local package_name

  if [[ ! -f "$rpm_file" ]]; then
    echo "❌ Q90 failed: lab package $rpm_file was not found."
    return 1
  fi

  if ! rpm -K "$rpm_file" >/dev/null 2>&1; then
    echo "❌ Q90 failed: $rpm_file is not a valid RPM package."
    return 1
  fi

  package_name="$(rpm -qp --qf '%{NAME}' "$rpm_file" 2>/dev/null || true)"

  if [[ -z "$package_name" ]]; then
    echo "❌ Q90 failed: could not determine package name."
    return 1
  fi

  if ! rpm -q "$package_name" >/dev/null 2>&1; then
    echo "❌ Q90 failed: package $package_name is not installed."
    return 1
  fi

  local installed_version package_version
  installed_version="$(rpm -q \
    --qf '%{VERSION}-%{RELEASE}' \
    "$package_name" 2>/dev/null)"

  package_version="$(rpm -qp \
    --qf '%{VERSION}-%{RELEASE}' \
    "$rpm_file" 2>/dev/null)"

  if [[ "$installed_version" != "$package_version" ]]; then
    echo "❌ Q90 failed: installed package version does not match the local RPM."
    echo "    Installed: $installed_version"
    echo "    Package:   $package_version"
    return 1
  fi

  echo "✅ Q90 PASSED: local RPM package installed correctly."
  return 0
}


# ===== Exercise Q91 =====
Q91_DESC="Install Flatpak and configure the Flathub repository named userrepo for user chisha only."

check_Q91() {
  local user="chisha"
  local home

  if ! getent passwd "$user" >/dev/null; then
    echo "❌ Q91 failed: user $user does not exist."
    return 1
  fi

  if ! command -v flatpak >/dev/null 2>&1; then
    echo "❌ Q91 failed: Flatpak is not installed."
    return 1
  fi

  home="$(getent passwd "$user" | cut -d: -f6)"

  local user_remotes
  user_remotes="$(
    runuser -u "$user" -- env HOME="$home" \
      flatpak remotes --user \
      --columns=name,url 2>/dev/null || true
  )"

  if ! awk -F'\t' '
      $1 == "userrepo" &&
      $2 ~ /^https:\/\/(dl\.)?flathub\.org\/repo\/?$/ {
        found=1
      }
      END { exit(found ? 0 : 1) }
    ' <<< "$user_remotes"; then
    echo "❌ Q91 failed: userrepo was not configured correctly for chisha."
    return 1
  fi

  # The same repository name must not exist system-wide.
  if flatpak remotes --system --columns=name 2>/dev/null |
    grep -Fxq 'userrepo'; then
    echo "❌ Q91 failed: userrepo was configured system-wide."
    echo "    The repository must exist for chisha only."
    return 1
  fi

  echo "✅ Q91 PASSED: user-only Flatpak repository configured correctly."
  return 0
}


# ===== Exercise Q92 =====
Q92_DESC="Install org.gimp.GIMP as a Flatpak application for user chisha only."

check_Q92() {
  local user="chisha"
  local app="org.gimp.GIMP"
  local home

  if ! getent passwd "$user" >/dev/null; then
    echo "❌ Q92 failed: user $user does not exist."
    return 1
  fi

  if ! command -v flatpak >/dev/null 2>&1; then
    echo "❌ Q92 failed: Flatpak is not installed."
    return 1
  fi

  home="$(getent passwd "$user" | cut -d: -f6)"

  if ! runuser -u "$user" -- env HOME="$home" \
    flatpak info --user "$app" >/dev/null 2>&1; then
    echo "❌ Q92 failed: $app is not installed for user chisha."
    return 1
  fi

  if flatpak info --system "$app" >/dev/null 2>&1; then
    echo "❌ Q92 failed: $app is installed system-wide."
    echo "    It must be installed for chisha only."
    return 1
  fi

  echo "✅ Q92 PASSED: GIMP installed in chisha's user Flatpak environment."
  return 0
}


# ===== Exercise Q93 =====
Q93_DESC="Create user developer, create groups devops and qa, and add developer to both groups without removing existing supplementary memberships."

check_Q93() {
  local user="developer"

  if ! getent passwd "$user" >/dev/null; then
    echo "❌ Q93 failed: user $user does not exist."
    return 1
  fi

  for group in devops qa; do
    if ! getent group "$group" >/dev/null; then
      echo "❌ Q93 failed: group $group does not exist."
      return 1
    fi

    if ! id -nG "$user" | tr ' ' '\n' | grep -Fxq "$group"; then
      echo "❌ Q93 failed: developer is not a member of $group."
      return 1
    fi
  done

  echo "✅ Q93 PASSED: developer has the required supplementary groups."
  return 0
}


# ===== Exercise Q94 =====
Q94_DESC="Rename group developers to engineering while preserving its GID and memberships."

check_Q94() {
  local original_gid_file="/var/lib/rhcsa-trainer/q94-developers-gid"
  local expected_gid current_gid

  if getent group developers >/dev/null; then
    echo "❌ Q94 failed: old group name developers still exists."
    return 1
  fi

  if ! getent group engineering >/dev/null; then
    echo "❌ Q94 failed: group engineering does not exist."
    return 1
  fi

  if [[ ! -f "$original_gid_file" ]]; then
    echo "❌ Q94 failed: reset metadata for the original GID is missing."
    return 1
  fi

  expected_gid="$(cat "$original_gid_file")"
  current_gid="$(getent group engineering | cut -d: -f3)"

  if [[ "$current_gid" != "$expected_gid" ]]; then
    echo "❌ Q94 failed: group GID changed during rename."
    echo "    Expected: $expected_gid"
    echo "    Current:  $current_gid"
    return 1
  fi

  # A prepared member confirms that memberships survived groupmod -n.
  if ! id -nG q94member 2>/dev/null |
    tr ' ' '\n' |
    grep -Fxq engineering; then
    echo "❌ Q94 failed: existing group membership was not preserved."
    return 1
  fi

  echo "✅ Q94 PASSED: group renamed with GID and membership preserved."
  return 0
}


# ===== Exercise Q95 =====
Q95_DESC="Modify developer to UID 4500, shell /bin/bash, and home /home/developer-new, moving the existing home contents."

check_Q95() {
  local user="developer"
  local expected_uid="4500"
  local expected_shell="/bin/bash"
  local expected_home="/home/developer-new"
  local marker="$expected_home/q95-original-home.txt"

  if ! getent passwd "$user" >/dev/null; then
    echo "❌ Q95 failed: user $user does not exist."
    return 1
  fi

  local passwd_entry uid home shell
  passwd_entry="$(getent passwd "$user")"
  uid="$(cut -d: -f3 <<< "$passwd_entry")"
  home="$(cut -d: -f6 <<< "$passwd_entry")"
  shell="$(cut -d: -f7 <<< "$passwd_entry")"

  if [[ "$uid" != "$expected_uid" ]]; then
    echo "❌ Q95 failed: developer UID is $uid; expected $expected_uid."
    return 1
  fi

  if [[ "$shell" != "$expected_shell" ]]; then
    echo "❌ Q95 failed: developer shell is $shell; expected $expected_shell."
    return 1
  fi

  if [[ "$home" != "$expected_home" ]]; then
    echo "❌ Q95 failed: developer home is $home; expected $expected_home."
    return 1
  fi

  if [[ ! -d "$expected_home" ]]; then
    echo "❌ Q95 failed: new home directory does not exist."
    return 1
  fi

  if [[ "$(stat -c '%U' "$expected_home" 2>/dev/null)" != "$user" ]]; then
    echo "❌ Q95 failed: new home directory is not owned by developer."
    return 1
  fi

  if [[ ! -f "$marker" ]]; then
    echo "❌ Q95 failed: original home contents were not moved."
    echo "    Missing: $marker"
    return 1
  fi

  if ! grep -Fxq 'Q95 original home content' "$marker"; then
    echo "❌ Q95 failed: moved marker file has incorrect content."
    return 1
  fi

  echo "✅ Q95 PASSED: developer account modified correctly."
  return 0
}


# ===== Exercise Q96 =====
Q96_DESC="Locate all regular files under /var owned by developer and copy them to /root/developer-files while preserving their filenames."

check_Q96() {
  local destination="/root/developer-files"
  local source_a="/var/tmp/q96-developer-alpha.txt"
  local source_b="/var/lib/rhcsa-trainer/q96-developer-beta.txt"

  if ! getent passwd developer >/dev/null; then
    echo "❌ Q96 failed: user developer does not exist."
    return 1
  fi

  if [[ ! -d "$destination" ]]; then
    echo "❌ Q96 failed: destination directory $destination does not exist."
    return 1
  fi

  for source in "$source_a" "$source_b"; do
    if [[ ! -f "$source" ]]; then
      echo "❌ Q96 failed: expected source test file is missing: $source"
      return 1
    fi

    if [[ "$(stat -c '%U' "$source" 2>/dev/null)" != "developer" ]]; then
      echo "❌ Q96 failed: test file is not owned by developer: $source"
      echo "    Complete Q95 before Q96."
      return 1
    fi

    local filename found
    filename="$(basename "$source")"

    found="$(
      find "$destination" \
        -type f \
        -name "$filename" \
        -print -quit 2>/dev/null
    )"

    if [[ -z "$found" ]]; then
      echo "❌ Q96 failed: $filename was not copied."
      return 1
    fi

    if ! cmp -s "$source" "$found"; then
      echo "❌ Q96 failed: copied file differs from source: $filename"
      return 1
    fi
  done

  echo "✅ Q96 PASSED: developer-owned files copied correctly."
  return 0
}


# ===== Exercise Q97 =====
Q97_DESC="Locate all directories with SGID enabled and save their absolute paths to /root/sgid-directories.txt."

check_Q97() {
  local output="/root/sgid-directories.txt"
  local sentinel="/var/tmp/rhcsa-special-perms/sgid-directory"

  if [[ ! -f "$output" ]]; then
    echo "❌ Q97 failed: $output does not exist."
    return 1
  fi

  if [[ ! -s "$output" ]]; then
    echo "❌ Q97 failed: $output is empty."
    return 1
  fi

  if ! grep -Fxq "$sentinel" "$output"; then
    echo "❌ Q97 failed: known SGID directory is missing."
    echo "    Missing: $sentinel"
    return 1
  fi

  local path bad=0

  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "$path" ]] && continue

    if [[ "$path" != /* ]]; then
      echo "❌ Q97 failed: path is not absolute: $path"
      bad=1
      continue
    fi

    if [[ ! -d "$path" ]]; then
      echo "❌ Q97 failed: listed path is not a directory: $path"
      bad=1
      continue
    fi

    if ! find "$path" \
      -maxdepth 0 \
      -type d \
      -perm -2000 \
      -print -quit 2>/dev/null |
      grep -q .; then
      echo "❌ Q97 failed: directory does not have SGID enabled: $path"
      bad=1
    fi
  done < "$output"

  if [[ "$bad" -ne 0 ]]; then
    return 1
  fi

  echo "✅ Q97 PASSED: SGID directory list is valid."
  return 0
}


# ===== Exercise Q98 =====
Q98_DESC="Locate all regular files with either SUID or SGID enabled and save their absolute paths to /root/special-permissions.txt."

check_Q98() {
  local output="/root/special-permissions.txt"
  local suid_sentinel="/var/tmp/rhcsa-special-perms/suid-test"
  local sgid_sentinel="/var/tmp/rhcsa-special-perms/sgid-test"

  if [[ ! -f "$output" ]]; then
    echo "❌ Q98 failed: $output does not exist."
    return 1
  fi

  if [[ ! -s "$output" ]]; then
    echo "❌ Q98 failed: $output is empty."
    return 1
  fi

  for sentinel in "$suid_sentinel" "$sgid_sentinel"; do
    if ! grep -Fxq "$sentinel" "$output"; then
      echo "❌ Q98 failed: known special-permission file is missing."
      echo "    Missing: $sentinel"
      return 1
    fi
  done

  local path bad=0

  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "$path" ]] && continue

    if [[ "$path" != /* ]]; then
      echo "❌ Q98 failed: path is not absolute: $path"
      bad=1
      continue
    fi

    if [[ ! -f "$path" ]]; then
      echo "❌ Q98 failed: listed path is not a regular file: $path"
      bad=1
      continue
    fi

    if ! find "$path" \
      -maxdepth 0 \
      -type f \
      -perm /6000 \
      -print -quit 2>/dev/null |
      grep -q .; then
      echo "❌ Q98 failed: file has neither SUID nor SGID: $path"
      bad=1
    fi
  done < "$output"

  if [[ "$bad" -ne 0 ]]; then
    return 1
  fi

  echo "✅ Q98 PASSED: SUID/SGID file list is valid."
  return 0
}

# ===== Exercise Q99 =====
Q99_DESC=" (Create if needed)Reduce the ext4 logical volume /dev/data_vg/data_lv from 500 MB to 300 MB. Ensure that the filesystem remains usable and its existing data is preserved."

# ===== Exercise Q99 =====

Q99_DESC="Reduce the ext4 logical volume /dev/data_vg/data_lv from 500 MB to approximately 300 MB. Ensure that the filesystem remains mounted and usable."

check_Q99() {
  local lvpath="/dev/data_vg/data_lv"
  local mountpoint="/mnt/data_lv"
  local fstype
  local size_raw
  local size_mb
  local testfile="$mountpoint/.q99-write-test"

  # LV must exist
  if ! lvs "$lvpath" >/dev/null 2>&1; then
    echo "❌ Q99 failed: logical volume $lvpath does not exist."
    return 1
  fi

  # Filesystem must be ext4
  fstype="$(
    blkid \
      -o value \
      -s TYPE \
      "$lvpath" 2>/dev/null ||
    true
  )"

  if [[ "$fstype" != "ext4" ]]; then
    echo "❌ Q99 failed: filesystem is '${fstype:-unknown}' (expected ext4)."
    return 1
  fi

  # LV final size should be approximately 300 MB
  size_raw="$(
    LC_ALL=C lvs \
      --noheadings \
      --units m \
      --nosuffix \
      -o lv_size \
      "$lvpath" 2>/dev/null |
    tr -d '[:space:]'
  )"

  size_mb="${size_raw%.*}"

  if [[ ! "$size_mb" =~ ^[0-9]+$ ]]; then
    echo "❌ Q99 failed: could not determine logical volume size."
    echo "    Raw value returned by lvs: '$size_raw'"
    return 1
  fi

  if (( size_mb < 290 || size_mb > 310 )); then
    echo "❌ Q99 failed: logical volume size is ${size_raw} MB."
    echo "    Expected approximately 300 MB."
    return 1
  fi

  # LV must be mounted at the expected mount point
  if ! findmnt -rn \
    -S "$lvpath" \
    -T "$mountpoint" \
    >/dev/null 2>&1; then

    echo "❌ Q99 failed: $lvpath is not mounted at $mountpoint."
    return 1
  fi

  # Filesystem must be writable
  if ! printf '%s\n' "Q99 writable test" \
    > "$testfile" 2>/dev/null; then

    echo "❌ Q99 failed: filesystem is mounted but not writable."
    return 1
  fi

  rm -f "$testfile"

  echo "✅ Q99 PASSED: ext4 filesystem and logical volume were reduced successfully."
  return 0
}

# ===== Exercise Q100 =====
Q100_DESC="Determine the filesystem type of /dev/archive_vg/archive_lv. If the filesystem supports shrinking, reduce it to 400 MB. If it does not support shrinking, do not perform a destructive operation."

check_Q100() {
  local lvpath="/dev/archive_vg/archive_lv"
  local mountpoint="/mnt/archive_lv"
  local marker="$mountpoint/q100-preserve.txt"
  local log="$RHCSA_SHM_DIR/cmd.log"

  # LV must exist
  if ! lvs "$lvpath" >/dev/null 2>&1; then
    echo "❌ Q100 failed: logical volume $lvpath does not exist."
    return 1
  fi

  # The reset intentionally prepares this LV with XFS.
  local fstype
  fstype="$(blkid -o value -s TYPE "$lvpath" 2>/dev/null || true)"

  if [[ "$fstype" != "xfs" ]]; then
    echo "❌ Q100 failed: filesystem is '$fstype' (expected XFS lab volume)."
    return 1
  fi

  # XFS must not be reduced.
  local size_raw size_mb
  size_raw="$(
    lvs \
      --noheadings \
      --units m \
      --nosuffix \
      -o lv_size \
      "$lvpath" 2>/dev/null |
    tr -d ' '
  )"

  size_mb="${size_raw%.*}"

  if [[ ! "$size_mb" =~ ^[0-9]+$ ]]; then
    echo "❌ Q100 failed: could not determine logical volume size."
    return 1
  fi

  if (( size_mb < 490 || size_mb > 510 )); then
    echo "❌ Q100 failed: XFS logical volume size was modified."
    echo "    Current size: ${size_raw} MB"
    echo "    Expected approximately 500 MB."
    return 1
  fi

  # Filesystem must remain mounted and usable
  if ! findmnt -rn -S "$lvpath" -T "$mountpoint" >/dev/null 2>&1; then
    echo "❌ Q100 failed: $lvpath is not mounted at $mountpoint."
    return 1
  fi

  if [[ ! -f "$marker" ]]; then
    echo "❌ Q100 failed: original XFS data was not preserved."
    return 1
  fi

  if ! grep -Fxq \
    'Q100 XFS data must not be destroyed' \
    "$marker"; then
    echo "❌ Q100 failed: preserved XFS file contains incorrect data."
    return 1
  fi

  # User must have inspected the filesystem.
  if [[ ! -f "$log" ]]; then
    echo "❌ Q100 failed: monitored command log was not found."
    return 1
  fi

  if ! grep -Eq \
    '(lsblk.*archive_vg|blkid.*archive_vg|findmnt.*archive_vg|file[[:space:]]+-s.*archive_vg)' \
    "$log"; then
    echo "❌ Q100 failed: filesystem inspection command was not detected."
    echo "    Use lsblk -f, blkid, findmnt, or file -s."
    return 1
  fi

  # Reject a destructive reduction attempt against this LV.
  if grep -Eq \
    'lvreduce.*archive_vg(/|-)archive_lv|lvreduce.*archive_lv' \
    "$log"; then
    echo "❌ Q100 failed: an lvreduce attempt against the XFS volume was detected."
    return 1
  fi

  echo "✅ Q100 PASSED: XFS was identified and no destructive reduction was performed."
  return 0
}


# ===== Exercise Q101 =====
Q101_DESC="Configure a permanent firewall rich rule that permits SSH access only from 192.168.100.0/24 and apply it immediately."

check_Q101() {
  local zone="${FIREWALL_ZONE:-public}"
  local rule='rule family="ipv4" source address="192.168.100.0/24" service name="ssh" accept'

  if ! systemctl is-active --quiet firewalld; then
    echo "❌ Q101 failed: firewalld is not running."
    return 1
  fi

  # Rich rule must exist permanently.
  if ! firewall-cmd \
    --permanent \
    --zone="$zone" \
    --query-rich-rule="$rule" \
    >/dev/null 2>&1; then
    echo "❌ Q101 failed: permanent SSH rich rule was not found."
    return 1
  fi

  # Rich rule must also exist at runtime.
  if ! firewall-cmd \
    --zone="$zone" \
    --query-rich-rule="$rule" \
    >/dev/null 2>&1; then
    echo "❌ Q101 failed: SSH rich rule was not applied at runtime."
    return 1
  fi

  # SSH must not remain globally open.
  if firewall-cmd \
    --permanent \
    --zone="$zone" \
    --query-service=ssh \
    >/dev/null 2>&1; then
    echo "❌ Q101 failed: SSH is still allowed globally in the permanent configuration."
    return 1
  fi

  if firewall-cmd \
    --zone="$zone" \
    --query-service=ssh \
    >/dev/null 2>&1; then
    echo "❌ Q101 failed: SSH is still allowed globally at runtime."
    return 1
  fi

  echo "✅ Q101 PASSED: SSH is allowed only from the required network."
  return 0
}


# ===== Exercise Q102 =====
Q102_DESC="Configure a permanent firewall rich rule that rejects HTTP access from 192.168.100.50 and apply it immediately."

check_Q102() {
  local zone="${FIREWALL_ZONE:-public}"
  local rule='rule family="ipv4" source address="192.168.100.50" service name="http" reject'

  if ! systemctl is-active --quiet firewalld; then
    echo "❌ Q102 failed: firewalld is not running."
    return 1
  fi

  if ! firewall-cmd \
    --permanent \
    --zone="$zone" \
    --query-rich-rule="$rule" \
    >/dev/null 2>&1; then
    echo "❌ Q102 failed: permanent HTTP reject rule was not found."
    return 1
  fi

  if ! firewall-cmd \
    --zone="$zone" \
    --query-rich-rule="$rule" \
    >/dev/null 2>&1; then
    echo "❌ Q102 failed: HTTP reject rule was not applied at runtime."
    return 1
  fi

  echo "✅ Q102 PASSED: HTTP access from 192.168.100.50 is rejected."
  return 0
}


# ===== Exercise Q103 =====
Q103_DESC="Configure a permanent firewall rich rule that permits HTTPS access from 192.168.100.0/24 and apply it immediately."

check_Q103() {
  local zone="${FIREWALL_ZONE:-public}"
  local rule='rule family="ipv4" source address="192.168.100.0/24" service name="https" accept'

  if ! systemctl is-active --quiet firewalld; then
    echo "❌ Q103 failed: firewalld is not running."
    return 1
  fi

  if ! firewall-cmd \
    --permanent \
    --zone="$zone" \
    --query-rich-rule="$rule" \
    >/dev/null 2>&1; then
    echo "❌ Q103 failed: permanent HTTPS rich rule was not found."
    return 1
  fi

  if ! firewall-cmd \
    --zone="$zone" \
    --query-rich-rule="$rule" \
    >/dev/null 2>&1; then
    echo "❌ Q103 failed: HTTPS rich rule was not applied at runtime."
    return 1
  fi

  echo "✅ Q103 PASSED: HTTPS access is allowed from the required network."
  return 0
}


# ===== Exercise Q104 =====
Q104_DESC="Configure a permanent firewall rich rule that logs and drops SSH connections from 10.10.10.0/24 using the prefix blocked-ssh."

check_Q104() {
  local zone="${FIREWALL_ZONE:-public}"
  local rule='rule family="ipv4" source address="10.10.10.0/24" service name="ssh" log prefix="blocked-ssh" limit value="5/m" drop'

  if ! systemctl is-active --quiet firewalld; then
    echo "❌ Q104 failed: firewalld is not running."
    return 1
  fi

  if ! firewall-cmd \
    --permanent \
    --zone="$zone" \
    --query-rich-rule="$rule" \
    >/dev/null 2>&1; then
    echo "❌ Q104 failed: permanent log-and-drop rule was not found."
    return 1
  fi

  if ! firewall-cmd \
    --zone="$zone" \
    --query-rich-rule="$rule" \
    >/dev/null 2>&1; then
    echo "❌ Q104 failed: log-and-drop rule was not applied at runtime."
    return 1
  fi

  echo "✅ Q104 PASSED: SSH attempts are logged and dropped."
  return 0
}


# ===== Exercise Q105 =====
Q105_DESC="Configure a permanent firewall rich rule that allows TCP port 8080 only from 172.16.50.0/24 and apply it immediately."

check_Q105() {
  local zone="${FIREWALL_ZONE:-public}"
  local rule='rule family="ipv4" source address="172.16.50.0/24" port port="8080" protocol="tcp" accept'

  if ! systemctl is-active --quiet firewalld; then
    echo "❌ Q105 failed: firewalld is not running."
    return 1
  fi

  if ! firewall-cmd \
    --permanent \
    --zone="$zone" \
    --query-rich-rule="$rule" \
    >/dev/null 2>&1; then
    echo "❌ Q105 failed: permanent port 8080 rich rule was not found."
    return 1
  fi

  if ! firewall-cmd \
    --zone="$zone" \
    --query-rich-rule="$rule" \
    >/dev/null 2>&1; then
    echo "❌ Q105 failed: port 8080 rich rule was not applied at runtime."
    return 1
  fi

  # Port 8080 must not remain globally open.
  if firewall-cmd \
    --permanent \
    --zone="$zone" \
    --query-port=8080/tcp \
    >/dev/null 2>&1; then
    echo "❌ Q105 failed: port 8080 is still globally allowed permanently."
    return 1
  fi

  if firewall-cmd \
    --zone="$zone" \
    --query-port=8080/tcp \
    >/dev/null 2>&1; then
    echo "❌ Q105 failed: port 8080 is still globally allowed at runtime."
    return 1
  fi

  echo "✅ Q105 PASSED: port 8080 is restricted to the required network."
  return 0
}

TASKS=(
  Q1 Q2 Q3 Q4 Q5 Q6 Q7 Q8 Q9 Q10
  Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20
  Q21 Q22 Q23 Q24 Q25 Q26 Q27 Q28 Q29 Q30
  Q31 Q32 Q33 Q34 Q35 Q36 Q37 Q38 Q39 Q40
  Q41 Q42 Q43 Q44 Q45 Q46 Q47 Q48 Q49 Q50
  Q51 Q52 Q53 Q54 Q55 Q56 Q57 Q58 Q59 Q60
  Q61 Q62 Q63 Q64 Q65 Q66 Q67 Q68 Q69 Q70
  Q71 Q72 Q73 Q74 Q75 Q76 Q77 Q78 Q79 Q80
  Q81 Q82 Q83 Q84 Q85 Q86 Q87 Q88 Q89 Q90
  Q91 Q92 Q93 Q94 Q95 Q96 Q97 Q98 Q99 Q100
  Q101 Q102 Q103 Q104 Q105
)

declare -A STATUS

evaluate_all() {
  local id
  local rc
  local check_timeout="${RHCSA_CHECK_TIMEOUT:-30}"

  # Exporta todas as funções apenas uma vez.
  export -f $(declare -F | awk '{print $3}')

  # Variáveis globais usadas dentro dos checks.
  export RHCSA_SHM_DIR

  for id in "${TASKS[@]}"; do
    printf 'Checking %s: ' "$id"

    set +e

    timeout \
      --signal=TERM \
      --kill-after=3s \
      "${check_timeout}s" \
      bash -c '"$1"' _ "check_${id}" \
      </dev/null

    rc=$?

    set -e

    case "$rc" in
      0)
        STATUS[$id]="${GREEN}PASSED${RESET}"
        echo "PASSED"
        ;;

      124|137)
        STATUS[$id]="${RED}TIMEOUT${RESET}"
        echo "TIMEOUT after ${check_timeout}s"
        ;;

      *)
        STATUS[$id]="${RED}PENDING${RESET}"
        echo "PENDING"
        ;;
    esac
  done
}

reset_all() {
  local TRAINER_HOME
  TRAINER_HOME="$(resolve_home)"
  [[ -n "$TRAINER_HOME" ]] || TRAINER_HOME="${HOME:-/root}"

  for id in "${TASKS[@]}"; do STATUS[$id]="${YELLOW}PENDING${RESET}"; done
  # Restore SELinux default state for next lab run
  sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config 2>/dev/null || true
  sudo setenforce 1 2>/dev/null || true
  sudo rm -f /.autorelabel 2>/dev/null || true
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

  #Clean Q5
  sudo rm -f "/root/web.txt" 2>/dev/null || true 
  sudo rm -f "/root/httpd-paths.txt.tmp" 2>/dev/null || true

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

  # Clean Q33
  rm -f rhel-file.txt 2>/dev/null || true

  ssh -o BatchMode=yes \
    -o PasswordAuthentication=no \
    -o PubkeyAuthentication=yes \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=accept-new \
    master-server@192.168.15.14 \
    'rm -f /home/master-server/rhel-file.txt' >/dev/null 2>&1 || true

# ===== Reset shared /dev/sdc storage labs =====
echo ">> Resetting shared /dev/sdc storage labs..."

sudo sed -i '\|/mnt/devops_lv|d;\|/mnt/cloud_lv|d;\|/mnt/xfs_lv|d' /etc/fstab 2>/dev/null || true

sudo umount /mnt/devops_lv 2>/dev/null || true
sudo umount /mnt/cloud_lv 2>/dev/null || true
sudo umount /mnt/xfs_lv 2>/dev/null || true

sudo lvremove -fy /dev/devops_vg/devops_lv 2>/dev/null || true
sudo lvremove -fy /dev/cloud_vg/cloud_lv 2>/dev/null || true
sudo lvremove -fy /dev/xfs_vg/xfs_lv 2>/dev/null || true

sudo vgremove -fy devops_vg 2>/dev/null || true
sudo vgremove -fy cloud_vg 2>/dev/null || true
sudo vgremove -fy xfs_vg 2>/dev/null || true

sudo pvremove -ffy /dev/sdc1 2>/dev/null || true
sudo pvremove -ffy /dev/sdc2 2>/dev/null || true
sudo pvremove -ffy /dev/sdc3 2>/dev/null || true
sudo pvremove -ffy /dev/sdc  2>/dev/null || true

sudo wipefs -af /dev/sdc1 2>/dev/null || true
sudo wipefs -af /dev/sdc2 2>/dev/null || true
sudo wipefs -af /dev/sdc3 2>/dev/null || true
sudo wipefs -af /dev/sdc  2>/dev/null || true

sudo dd if=/dev/zero of=/dev/sdc bs=1M count=10 conv=fsync 2>/dev/null || true

sudo parted -s /dev/sdc mklabel gpt 2>/dev/null || true

# /dev/sdc1 -> Q34 devops_vg/devops_lv
sudo parted -s /dev/sdc mkpart primary 1MiB 800MiB 2>/dev/null || true

# /dev/sdc2 -> Q65 xfs_vg/xfs_lv
sudo parted -s /dev/sdc mkpart primary 800MiB 1600MiB 2>/dev/null || true

sudo partprobe /dev/sdc 2>/dev/null || true
sudo udevadm settle 2>/dev/null || true

sudo rm -rf /mnt/devops_lv 2>/dev/null || true
sudo rm -rf /mnt/cloud_lv  2>/dev/null || true
sudo rm -rf /mnt/xfs_lv    2>/dev/null || true

# Recreate initial Q65 state on /dev/sdc2
if [ -b /dev/sdc2 ]; then
  sudo pvcreate -ff -y /dev/sdc2 >/dev/null
  sudo vgcreate xfs_vg /dev/sdc2 >/dev/null
  sudo lvcreate -L 300M -n xfs_lv xfs_vg >/dev/null

  sudo mkfs.xfs -f /dev/xfs_vg/xfs_lv >/dev/null

  sudo mkdir -p /mnt/xfs_lv

  sudo sed -i '\|/mnt/xfs_lv|d' /etc/fstab 2>/dev/null || true
  echo '/dev/xfs_vg/xfs_lv /mnt/xfs_lv xfs defaults 0 0' | sudo tee -a /etc/fstab >/dev/null

  sudo mount /mnt/xfs_lv || {
    echo "WARN: failed to mount /mnt/xfs_lv"
    sudo mount -av
  }
else
  echo "WARN: /dev/sdc2 not found; Q65 XFS lab was not recreated."
fi

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
  sudo firewall-cmd --remove-service=ssh --permanent 2>/dev/null || true
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


  #Clean Q47-Q51 network
  sudo nmcli con delete static-enp0s8 2>/dev/null || true
  sudo nmcli con mod enp0s8 ipv4.method auto ipv4.addresses "" ipv4.gateway "" ipv4.dns "" ipv6.method auto ipv6.addresses "" ipv6.gateway "" connection.autoconnect no 2>/dev/null || true
  sudo hostnamectl set-hostname localhost.localdomain 2>/dev/null || true

  #Clean Q52-Q54 processes/log-only tasks
  sudo pkill -x stress-ng 2>/dev/null || true

  #Clean Q57 journal
  sudo rm -rf /var/log/journal 2>/dev/null || true
  sudo systemctl restart systemd-journald 2>/dev/null || true

  #Clean Q58-Q59 chrony
  sudo sed -i '/pool.ntp.org/d;/server1.example.com/d' /etc/chrony.conf 2>/dev/null || true
  sudo rm -f /etc/chrony.d/rhcsa-trainer.conf 2>/dev/null || true
  sudo systemctl disable --now chronyd 2>/dev/null || true

  #Clean Q60-Q62 SELinux/httpd
  sudo setsebool -P httpd_enable_homedirs off 2>/dev/null || true
  sudo semanage fcontext -d '/webdata(/.*)?' 2>/dev/null || true
  sudo rm -rf /webdata 2>/dev/null || true
  sudo semanage port -d -t http_port_t -p tcp 8080 2>/dev/null || true
  sudo sed -i '/^[[:space:]]*Listen[[:space:]]\+8080/d' /etc/httpd/conf/httpd.conf 2>/dev/null || true

  #Clean Q63-Q65 systemd service
  sudo systemctl disable --now backup.service 2>/dev/null || true
  sudo rm -f /etc/systemd/system/backup.service /etc/systemd/system/broken.service /root/backup.sh 2>/dev/null || true
  sudo systemctl daemon-reload 2>/dev/null || true

# Clean Q65 XFS lab
# Handled by the shared /dev/sdc reset block.

sudo lvremove -fy /dev/xfs_vg/xfs_lv 2>/dev/null || true
sudo vgremove -fy xfs_vg 2>/dev/null || true
sudo pvremove -ffy /dev/sde1 2>/dev/null || true

sudo wipefs -af /dev/sde1 2>/dev/null || true
sudo parted -s /dev/sde rm 1 2>/dev/null || true
sudo partprobe /dev/sde 2>/dev/null || true
sudo udevadm settle 2>/dev/null || true

sudo rm -rf /mnt/xfs_lv 2>/dev/null || true

# Recreate initial Q65 state using isolated disk /dev/sde
if [ -b /dev/sde ]; then
  sudo parted -s /dev/sde mklabel gpt
  sudo parted -s /dev/sde mkpart primary 1MiB 600MiB
  sudo partprobe /dev/sde
  sudo udevadm settle

  sudo pvcreate -ff -y /dev/sde1
  sudo vgcreate xfs_vg /dev/sde1
  sudo lvcreate -L 400M -n xfs_lv xfs_vg

  sudo mkfs.xfs -f /dev/xfs_vg/xfs_lv

  sudo mkdir -p /mnt/xfs_lv
  echo '/dev/xfs_vg/xfs_lv /mnt/xfs_lv xfs defaults 0 0' | sudo tee -a /etc/fstab >/dev/null

  sudo mount -a
else
  echo "WARN: /dev/sde not found; Q65 XFS lab was not recreated."
fi

  # Clean Q66-Q68 firewall
sudo systemctl enable --now firewalld 2>/dev/null || true

sudo firewall-cmd --remove-port=8080/tcp 2>/dev/null || true
sudo firewall-cmd --remove-service=nfs 2>/dev/null || true
sudo firewall-cmd --remove-rich-rule='rule family="ipv4" source address="192.168.100.0/24" service name="ssh" accept' 2>/dev/null || true

sudo firewall-cmd --permanent --remove-port=8080/tcp 2>/dev/null || true
sudo firewall-cmd --permanent --remove-service=nfs 2>/dev/null || true
sudo firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="192.168.100.0/24" service name="ssh" accept' 2>/dev/null || true

sudo firewall-cmd --reload 2>/dev/null || true
sudo systemctl disable --now firewalld 2>/dev/null || true

  #Clean Q69-Q70 scripts
  sudo rm -f /root/check-user.sh /root/check-files.sh /tmp/Q70_exists_a /tmp/Q70_exists_b /tmp/Q70_missing_c 2>/dev/null || true

    # =========================================================
  # Reset Q71-Q80: special permissions, find and ACL exercises
  # =========================================================

  echo ">> Resetting Q71-Q80 permissions and ACL labs..."

  # Q71: SUID file
  sudo rm -rf /secure 2>/dev/null || true

  # Q72: SGID shared directory
  sudo rm -rf /shared-devs 2>/dev/null || true

  # Q73: sticky bit directory
  sudo rm -rf /public-share 2>/dev/null || true

  # Q74-Q75: generated answer files
  sudo rm -f \
    /root/suid-files.txt \
    /root/sgid-files.txt \
    2>/dev/null || true

  # Recreate deterministic SUID and SGID test files.
  # These ensure that Q74 and Q75 always have known results.
  sudo rm -rf /var/tmp/rhcsa-special-perms 2>/dev/null || true
  sudo mkdir -p /var/tmp/rhcsa-special-perms

  sudo install \
    -o root \
    -g root \
    -m 4755 \
    /dev/null \
    /var/tmp/rhcsa-special-perms/suid-test

  sudo install \
    -o root \
    -g root \
    -m 2755 \
    /dev/null \
    /var/tmp/rhcsa-special-perms/sgid-test

  # Q76: ACL fstab copy
  sudo rm -rf /acl-lab 2>/dev/null || true

  # Q77: report ACL
  sudo rm -rf /project 2>/dev/null || true

  # Q78 and Q80: default ACL and ACL backup
  sudo rm -rf /projects 2>/dev/null || true
  sudo rm -f /root/projects.acl 2>/dev/null || true

  # Q79: finance default ACL
  sudo rm -rf /shared-reports 2>/dev/null || true

  echo ">> Q71-Q80 reset completed."

    # =========================================================
  # Reset Q81-Q87: cron and systemd timer exercises
  # =========================================================

  echo ">> Resetting Q81-Q87 cron and timer labs..."

  # ---------------------------------------------------------
  # Q81-Q83: remove only the entries created by these labs
  # ---------------------------------------------------------

  remove_cron_matching() {
    local user="$1"
    local pattern="$2"
    local tmp

    tmp="$(mktemp)"

    crontab -u "$user" -l 2>/dev/null |
      grep -Ev "$pattern" > "$tmp" || true

    if [[ -s "$tmp" ]]; then
      crontab -u "$user" "$tmp" 2>/dev/null || true
    else
      crontab -u "$user" -r 2>/dev/null || true
    fi

    rm -f "$tmp"
  }

  # Q81
  if getent passwd student >/dev/null; then
    remove_cron_matching \
      student \
      'daily backup|30[[:space:]]+1[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*'
  fi

  # Q82 and Q83
  remove_cron_matching \
    root \
    '/root/cron-success|/var/log/cron-test\.log'

  sudo rm -f \
    /root/cron-success \
    /var/log/cron-test.log \
    2>/dev/null || true

  # Keep crond available as a normal base system service.
  sudo systemctl enable --now crond 2>/dev/null || true

  # ---------------------------------------------------------
  # Q84: reset cron authorization files
  # ---------------------------------------------------------

  sudo rm -f /etc/cron.allow 2>/dev/null || true

  # Keep the standard cron.deny file present and empty.
  sudo truncate -s 0 /etc/cron.deny 2>/dev/null || true
  sudo chown root:root /etc/cron.deny 2>/dev/null || true
  sudo chmod 600 /etc/cron.deny 2>/dev/null || true

  # ---------------------------------------------------------
  # Q85: system hello timer
  # ---------------------------------------------------------

  sudo systemctl disable --now hello.timer \
    >/dev/null 2>&1 || true

  sudo systemctl stop hello.service \
    >/dev/null 2>&1 || true

  sudo rm -f \
    /etc/systemd/system/hello.service \
    /etc/systemd/system/hello.timer \
    /etc/systemd/system/timers.target.wants/hello.timer \
    2>/dev/null || true

  # ---------------------------------------------------------
  # Q86: ten-minute timer
  # ---------------------------------------------------------

  sudo systemctl disable --now timer-test.timer \
    >/dev/null 2>&1 || true

  sudo systemctl stop timer-test.service \
    >/dev/null 2>&1 || true

  sudo rm -f \
    /etc/systemd/system/timer-test.service \
    /etc/systemd/system/timer-test.timer \
    /etc/systemd/system/timers.target.wants/timer-test.timer \
    /var/log/timer-test.log \
    2>/dev/null || true

  # ---------------------------------------------------------
  # Q87: user timer for chisha
  # ---------------------------------------------------------

  if getent passwd chisha >/dev/null; then
    chisha_home="$(getent passwd chisha | cut -d: -f6)"
    chisha_uid="$(id -u chisha)"
    chisha_runtime="/run/user/$chisha_uid"

    if [[ -d "$chisha_runtime" ]]; then
      sudo runuser -u chisha -- env \
        XDG_RUNTIME_DIR="$chisha_runtime" \
        systemctl --user disable --now hello-user.timer \
        >/dev/null 2>&1 || true

      sudo runuser -u chisha -- env \
        XDG_RUNTIME_DIR="$chisha_runtime" \
        systemctl --user daemon-reload \
        >/dev/null 2>&1 || true
    fi

    sudo rm -f \
      "$chisha_home/.config/systemd/user/hello-user.service" \
      "$chisha_home/.config/systemd/user/hello-user.timer" \
      "$chisha_home/.config/systemd/user/timers.target.wants/hello-user.timer" \
      2>/dev/null || true

    sudo loginctl disable-linger chisha \
      >/dev/null 2>&1 || true
  fi

  sudo systemctl daemon-reload
  sudo systemctl reset-failed \
    hello.service \
    timer-test.service \
    >/dev/null 2>&1 || true

  echo ">> Q81-Q87 reset completed."

    # =========================================================
  # Reset Q88-Q98: RPM, Flatpak, users, groups and find labs
  # =========================================================

  echo ">> Resetting Q88-Q98 package and account labs..."

  # ---------------------------------------------------------
  # Q88-Q89: generated query output
  # ---------------------------------------------------------

  sudo rm -f \
    /root/httpd-version.txt \
    /root/ssh-package.txt \
    2>/dev/null || true

  # httpd and openssh-clients are base requirements for these labs.
  # Installation should preferably be guaranteed by the RPM spec.
  if ! rpm -q httpd >/dev/null 2>&1; then
    sudo dnf install -y httpd >/dev/null 2>&1 || \
      echo "WARN: httpd could not be installed; Q88 may not be available."
  fi

  if ! rpm -q openssh-clients >/dev/null 2>&1; then
    sudo dnf install -y openssh-clients >/dev/null 2>&1 || \
      echo "WARN: openssh-clients could not be installed; Q89 may not be available."
  fi

  # ---------------------------------------------------------
  # Q90: local demo RPM
  # ---------------------------------------------------------

  sudo mkdir -p /root/packages
  sudo rm -f /root/packages/demo-package.rpm

  DEMO_RPM_SOURCE="/usr/share/rhcsa-trainer/demo-package.rpm"

  if [[ -f "$DEMO_RPM_SOURCE" ]]; then
    demo_package_name="$(
      rpm -qp --qf '%{NAME}' "$DEMO_RPM_SOURCE" 2>/dev/null || true
    )"

    if [[ -n "$demo_package_name" ]]; then
      sudo dnf remove -y "$demo_package_name" \
        >/dev/null 2>&1 || true
    fi

    sudo install \
      -o root \
      -g root \
      -m 0644 \
      "$DEMO_RPM_SOURCE" \
      /root/packages/demo-package.rpm
  else
    echo "WARN: $DEMO_RPM_SOURCE not found; Q90 package was not prepared."
  fi

  # ---------------------------------------------------------
  # Q91-Q92: Flatpak user repository and application
  # ---------------------------------------------------------

  if ! getent passwd chisha >/dev/null; then
    sudo useradd -m chisha
  fi

  chisha_home="$(getent passwd chisha | cut -d: -f6)"

  if command -v flatpak >/dev/null 2>&1; then
    sudo runuser -u chisha -- env HOME="$chisha_home" \
      flatpak uninstall \
      --user \
      --noninteractive \
      --delete-data \
      org.gimp.GIMP \
      >/dev/null 2>&1 || true

    sudo runuser -u chisha -- env HOME="$chisha_home" \
      flatpak remote-delete \
      --user \
      --force \
      userrepo \
      >/dev/null 2>&1 || true

    # Remove a system-wide repository with the exercise name,
    # but do not remove unrelated Flatpak remotes.
    sudo flatpak remote-delete \
      --system \
      --force \
      userrepo \
      >/dev/null 2>&1 || true
  fi

  # ---------------------------------------------------------
  # Q93 and Q95: developer account and supplementary groups
  # ---------------------------------------------------------

  # Remove the account from a previous attempt.
  if getent passwd developer >/dev/null; then
    sudo pkill -u developer 2>/dev/null || true
    sudo userdel -r developer 2>/dev/null || true
  fi

  sudo rm -rf \
    /home/developer \
    /home/developer-new \
    2>/dev/null || true

  # Remove exercise groups. They must be created by the student in Q93.
  for group in devops qa; do
    if getent group "$group" >/dev/null; then
      # Avoid failure if an older lab user still has this as primary group.
      members="$(
        getent group "$group" |
        cut -d: -f4
      )"

      if [[ -z "$members" ]]; then
        sudo groupdel "$group" 2>/dev/null || true
      else
        echo "WARN: group $group still has members and was not removed."
      fi
    fi
  done

  # Q95 needs content in developer's original home.
  # Because developer is created during Q93, prepare a staging file.
  sudo mkdir -p /var/lib/rhcsa-trainer/q95-template

  echo 'Q95 original home content' |
    sudo tee \
      /var/lib/rhcsa-trainer/q95-template/q95-original-home.txt \
      >/dev/null

  sudo chown root:root \
    /var/lib/rhcsa-trainer/q95-template/q95-original-home.txt

  sudo chmod 0644 \
    /var/lib/rhcsa-trainer/q95-template/q95-original-home.txt

  # ---------------------------------------------------------
  # Q94: group rename lab
  # ---------------------------------------------------------

  if getent passwd q94member >/dev/null; then
    sudo pkill -u q94member 2>/dev/null || true
    sudo userdel -r q94member 2>/dev/null || true
  fi

  for group in engineering developers; do
    if getent group "$group" >/dev/null; then
      sudo groupdel "$group" 2>/dev/null || true
    fi
  done

  # Use a fixed GID to make preservation objectively testable.
  Q94_GID=4600

  # Avoid collision when 4600 already belongs to another group.
  if getent group "$Q94_GID" >/dev/null; then
    Q94_GID=4601
  fi

  sudo groupadd -g "$Q94_GID" developers
  sudo useradd -m -G developers q94member

  sudo mkdir -p /var/lib/rhcsa-trainer
  echo "$Q94_GID" |
    sudo tee /var/lib/rhcsa-trainer/q94-developers-gid \
    >/dev/null

  sudo chmod 0644 \
    /var/lib/rhcsa-trainer/q94-developers-gid

  # ---------------------------------------------------------
  # Q96: files that will belong to developer after UID change
  # ---------------------------------------------------------

  sudo rm -rf /root/developer-files
  sudo rm -f \
    /var/tmp/q96-developer-alpha.txt \
    /var/lib/rhcsa-trainer/q96-developer-beta.txt \
    2>/dev/null || true

  echo 'Q96 alpha developer file' |
    sudo tee /var/tmp/q96-developer-alpha.txt \
    >/dev/null

  echo 'Q96 beta developer file' |
    sudo tee /var/lib/rhcsa-trainer/q96-developer-beta.txt \
    >/dev/null

  # Preassign numeric UID 4500.
  # After Q95 changes developer to UID 4500, these become developer-owned.
  sudo chown 4500:root \
    /var/tmp/q96-developer-alpha.txt \
    /var/lib/rhcsa-trainer/q96-developer-beta.txt

  sudo chmod 0644 \
    /var/tmp/q96-developer-alpha.txt \
    /var/lib/rhcsa-trainer/q96-developer-beta.txt

  # ---------------------------------------------------------
  # Q97-Q98: deterministic special-permission objects
  # ---------------------------------------------------------

  sudo mkdir -p /var/tmp/rhcsa-special-perms

  sudo rm -rf \
    /var/tmp/rhcsa-special-perms/sgid-directory \
    2>/dev/null || true

  sudo mkdir \
    /var/tmp/rhcsa-special-perms/sgid-directory

  sudo chown root:root \
    /var/tmp/rhcsa-special-perms/sgid-directory

  sudo chmod 2755 \
    /var/tmp/rhcsa-special-perms/sgid-directory

  # Reapply sentinels in case earlier exercises changed them.
  sudo touch \
    /var/tmp/rhcsa-special-perms/suid-test \
    /var/tmp/rhcsa-special-perms/sgid-test

  sudo chown root:root \
    /var/tmp/rhcsa-special-perms/suid-test \
    /var/tmp/rhcsa-special-perms/sgid-test

  sudo chmod 4755 \
    /var/tmp/rhcsa-special-perms/suid-test

  sudo chmod 2755 \
    /var/tmp/rhcsa-special-perms/sgid-test

  sudo rm -f \
    /root/sgid-directories.txt \
    /root/special-permissions.txt \
    2>/dev/null || true

  echo ">> Q88-Q98 reset completed."

    # =========================================================
  # Reset Q99-Q105: LVM reduction and firewalld rich rules
  # =========================================================

  echo ">> Resetting Q99-Q105 LVM and firewall labs..."

  # ---------------------------------------------------------
  # Q99-Q100: remove previous LVM loop laboratories
  # ---------------------------------------------------------

  sudo umount /mnt/data_lv \
    >/dev/null 2>&1 || true

  sudo umount /mnt/archive_lv \
    >/dev/null 2>&1 || true

  if sudo lvs /dev/data_vg/data_lv \
    >/dev/null 2>&1; then
    sudo lvremove -fy /dev/data_vg/data_lv \
      >/dev/null 2>&1 || true
  fi

  if sudo vgs data_vg \
    >/dev/null 2>&1; then
    sudo vgremove -fy data_vg \
      >/dev/null 2>&1 || true
  fi

  if sudo lvs /dev/archive_vg/archive_lv \
    >/dev/null 2>&1; then
    sudo lvremove -fy /dev/archive_vg/archive_lv \
      >/dev/null 2>&1 || true
  fi

  if sudo vgs archive_vg \
    >/dev/null 2>&1; then
    sudo vgremove -fy archive_vg \
      >/dev/null 2>&1 || true
  fi

  # Read loop device paths saved by the previous reset.
  if [[ -f /var/lib/rhcsa-trainer/q99-loop-device ]]; then
    q99_old_loop="$(
      cat /var/lib/rhcsa-trainer/q99-loop-device
    )"

    sudo pvremove -ff -y "$q99_old_loop" \
      >/dev/null 2>&1 || true

    sudo losetup -d "$q99_old_loop" \
      >/dev/null 2>&1 || true
  fi

  if [[ -f /var/lib/rhcsa-trainer/q100-loop-device ]]; then
    q100_old_loop="$(
      cat /var/lib/rhcsa-trainer/q100-loop-device
    )"

    sudo pvremove -ff -y "$q100_old_loop" \
      >/dev/null 2>&1 || true

    sudo losetup -d "$q100_old_loop" \
      >/dev/null 2>&1 || true
  fi

    # Detach stale loop devices that still reference the lab images.
  while read -r stale_loop; do
    [[ -z "$stale_loop" ]] && continue

    sudo losetup -d "$stale_loop" \
      >/dev/null 2>&1 || true
  done < <(
    sudo losetup -j \
      /var/lib/rhcsa-trainer/q99-lvm.img \
      2>/dev/null |
    cut -d: -f1
  )

  while read -r stale_loop; do
    [[ -z "$stale_loop" ]] && continue

    sudo losetup -d "$stale_loop" \
      >/dev/null 2>&1 || true
  done < <(
    sudo losetup -j \
      /var/lib/rhcsa-trainer/q100-lvm.img \
      2>/dev/null |
    cut -d: -f1
  )

  sudo rm -f \
    /var/lib/rhcsa-trainer/q99-loop-device \
    /var/lib/rhcsa-trainer/q100-loop-device \
    /var/lib/rhcsa-trainer/q99-lvm.img \
    /var/lib/rhcsa-trainer/q100-lvm.img \
    2>/dev/null || true

  sudo rm -rf \
    /mnt/data_lv \
    /mnt/archive_lv \
    2>/dev/null || true

  sudo mkdir -p \
    /var/lib/rhcsa-trainer \
    /mnt/data_lv \
    /mnt/archive_lv

  # ---------------------------------------------------------
  # Q99: ext4 LV, initially 500 MB
  # ---------------------------------------------------------

  sudo truncate \
    -s 700M \
    /var/lib/rhcsa-trainer/q99-lvm.img

  q99_loop="$(
    sudo losetup \
      --find \
      --show \
      /var/lib/rhcsa-trainer/q99-lvm.img
  )"

  echo "$q99_loop" |
    sudo tee \
      /var/lib/rhcsa-trainer/q99-loop-device \
      >/dev/null

  sudo pvcreate -ff -y "$q99_loop"
  sudo vgcreate data_vg "$q99_loop"
  sudo lvcreate \
    -L 500M \
    -n data_lv \
    data_vg

  sudo mkfs.ext4 \
    -F \
    /dev/data_vg/data_lv \
    >/dev/null

  sudo mount \
    /dev/data_vg/data_lv \
    /mnt/data_lv

  echo 'Q99 data must survive logical volume reduction' |
    sudo tee \
      /mnt/data_lv/q99-preserve.txt \
      >/dev/null

  sudo sync

  # ---------------------------------------------------------
  # Q100: XFS LV, initially 500 MB
  # ---------------------------------------------------------

  sudo truncate \
    -s 700M \
    /var/lib/rhcsa-trainer/q100-lvm.img

  q100_loop="$(
    sudo losetup \
      --find \
      --show \
      /var/lib/rhcsa-trainer/q100-lvm.img
  )"

  echo "$q100_loop" |
    sudo tee \
      /var/lib/rhcsa-trainer/q100-loop-device \
      >/dev/null

  sudo pvcreate -ff -y "$q100_loop"
  sudo vgcreate archive_vg "$q100_loop"
  sudo lvcreate \
    -L 500M \
    -n archive_lv \
    archive_vg

  sudo mkfs.xfs \
    -f \
    /dev/archive_vg/archive_lv \
    >/dev/null

  sudo mount \
    /dev/archive_vg/archive_lv \
    /mnt/archive_lv

  echo 'Q100 XFS data must not be destroyed' |
    sudo tee \
      /mnt/archive_lv/q100-preserve.txt \
      >/dev/null

  sudo sync

  # ---------------------------------------------------------
  # Q101-Q105: firewalld rich rules
  # ---------------------------------------------------------

  FIREWALL_ZONE="${FIREWALL_ZONE:-public}"

  sudo systemctl enable --now firewalld \
    >/dev/null 2>&1 || true

  q101_rule='rule family="ipv4" source address="192.168.100.0/24" service name="ssh" accept'
  q102_rule='rule family="ipv4" source address="192.168.100.50" service name="http" reject'
  q103_rule='rule family="ipv4" source address="192.168.100.0/24" service name="https" accept'
  q104_rule='rule family="ipv4" source address="10.10.10.0/24" service name="ssh" log prefix="blocked-ssh" limit value="5/m" drop'
  q105_rule='rule family="ipv4" source address="172.16.50.0/24" port port="8080" protocol="tcp" accept'

  # Remove exercise rules from permanent configuration.
  for rule in \
    "$q101_rule" \
    "$q102_rule" \
    "$q103_rule" \
    "$q104_rule" \
    "$q105_rule"
  do
    sudo firewall-cmd \
      --permanent \
      --zone="$FIREWALL_ZONE" \
      --remove-rich-rule="$rule" \
      >/dev/null 2>&1 || true
  done

  # Remove exercise rules from runtime configuration.
  for rule in \
    "$q101_rule" \
    "$q102_rule" \
    "$q103_rule" \
    "$q104_rule" \
    "$q105_rule"
  do
    sudo firewall-cmd \
      --zone="$FIREWALL_ZONE" \
      --remove-rich-rule="$rule" \
      >/dev/null 2>&1 || true
  done

  # Establish the initial challenge state:
  # SSH and port 8080 are globally open and must be restricted
  # by Q101 and Q105.
  sudo firewall-cmd \
    --permanent \
    --zone="$FIREWALL_ZONE" \
    --add-service=ssh \
    >/dev/null 2>&1 || true

  sudo firewall-cmd \
    --permanent \
    --zone="$FIREWALL_ZONE" \
    --add-port=8080/tcp \
    >/dev/null 2>&1 || true

  sudo firewall-cmd --reload \
    >/dev/null 2>&1 || true

  echo ">> Q99-Q105 reset completed."

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