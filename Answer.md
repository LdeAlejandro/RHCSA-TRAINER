## Question 1: Use vim to create and save a file hello.txt containing 'hello world'

### Answer: 

```bash
vim hello.txt 
```
save the file

check with rhcsa-trainer eval

---

## Question 2: Create SSH key-based authentication

### Answer: 

```bash
# 1. Generate RSA key with 4096 bits (on local machine)
ssh-keygen -t rsa -b 4096
# -> Press ENTER to accept default path (~/.ssh/id_rsa)
# -> Press ENTER again for empty passphrase (RHCSA)

# 2. Copy the public key to the remote server
ssh-copy-id ssh_username@server_ip_or_hostname
# (Enter password once)

# 3. (Optional) Fix ownership on the remote server (only if needed)
sudo chown -R ssh_username:ssh_username /home/ssh_username/.ssh

# 4. Test SSH login (should not ask for password)
ssh ssh_username@server_ip_or_hostname
```

```bash
#to check progress:
check with rhcsa-trainer eval
```

## Question 3: Check System Logs

### Answer:

```bash
# 1. View recent system logs with explanations
sudo journalctl -xe

# 2. Check authentication and SSH logs
sudo cat /var/log/secure

# 3. (Optional) Filter logs for a specific service
sudo journalctl -u sshd
```
---

## Question 4: Move and Copy Files

### Answer:

```bash
# 1. Move the file from 'files' to 'Documents'
mv "/trainer/files/move me to document and copy me to backup" /trainer/Documents/

# 2. Copy the file from 'Documents' to 'DocumentBackup'
cp "/trainer/Documents/move me to document and copy me to backup" /trainer/DocumentBackup/
```
---

## Question 5: Find the string "Listen" in /etc/httpd/conf/httpd.conf and save the output to /root/web.txt

### Answer:

```bash
# 1. Find the string "Listen" in /etc/httpd/conf/httpd.conf and save the output to /root/web.txt
 sudo grep Listen /etc/httpd/conf/httpd.conf >> /root/web.txt

 #OR (if not from root user)
 sudo bash -c 'grep Listen /etc/httpd/conf/httpd.conf >> /root/web.txt'
 ```
---

## Question 6: Create a gzip-compressed tar archive of /etc named etc_vault.tar.gz in your home directory under vaults (~/vaults).

### Answer:
```bash
# Create directory
mkdir ~/vaults

#compresse files
tar ~cvfz /vaults/etc_vault.tar.gz /etc
```
---
## Question 7: File Links - Create a file file_a in shorts directory create soft link file_b pointing to file_a

### Answer:
```bash
# Create directory
mkdir /shorts

#Create file
touch /shorts/file_a

#create softlink
ln -s /shorts/file_a /file_b

## if the link was created and is having error sudo 
ln -snf /shorts/file_a /file_b

```
---
## Question 8: File Links - Create a hard link of the file in hardfiles directory to file_c

### Answer:
```bash
#create hardlink
ln /hardfiles/file_data /file_c
```
---
## Question 9: Find files in /usr that are greater than 3MB but < 10MB and copy them to /bigfiles directory.

### Answer:
```bash
#create directory
sudo mkdir /bigfiles

#find and copy files to directory
sudo find /usr -type f -size +3M -size -10M -exec cp {} /bigfiles \;


```
--- 

## Question 10: Find files in /etc modified more than 120 days ago and copy them to /var/tmp/twenty/

### Answer:
```bash
#create directory
sudo mkdir /var/tmp/twenty

#find files
sudo find /etc -type f -mtime +120 -exec cp {} /var/tmp/twenty \;
```
--- 

## Question 11:Find all temp files owned by user rhel and copy them to /var/tmp/rhel-files.

### Answer:
```bash
#create directory
sudo mkdir -p /var/tmp/rhel-files
#find files
sudo find /home /var /etc -type f -user rhel -exec cp {} /var/tmp/rhel-files \;
```
--- 

## Question 12: Find a file named "httpd.conf" and save the absolute paths to /root/httpd-paths.txt.

### Answer:
```bash
#find and copy the file to directory

find / -type f -name httpd.conf >> /root/httpd-paths.txt
#OR
sudo sh -c 'find / -type f -name httpd.conf >> /root/httpd-paths.txt'
```
--- 

## Question 13: Copy the contents of /etc/fstab to /var/tmp, Set the file ownership to root, Ensure no execute permissions for anyone

### Answer:
```bash
# Copy /etc/fstab to /var/tmp
cp /etc/fstab /var/tmp/

# Set file owner and group to root
chown root:root /var/tmp/fstab

# Set permissions to read/write for owner, read-only for others (no execute)
chmod 644 /var/tmp/fstab

```
## Question 14: Give full permissions to everyone on `/var/tmp/chmod_lab/public.log` and set owner:group to `root:root`

### Answer:
```bash
# Everyone can read, write, and execute this file
chmod 777 /var/tmp/chmod_lab/public.log

# Set file owner and group to root
chown root:root /var/tmp/chmod_lab/public.log
```

---

## Question 15: Allow the owner to read/write/execute, while others can only read and execute on `/var/tmp/chmod_lab/script.sh`. Set owner:group to `devops:devs`.

### Answer:
```bash
# Owner can do everything; others can read and execute only
chmod 755 /var/tmp/chmod_lab/script.sh

# Create the group
sudo groupadd devs

# Create the user and assign to group
sudo useradd -g devs devops

# Assign file ownership
chown devops:devs /var/tmp/chmod_lab/script.sh
```

---

## Question 16: Allow only the owner to read, write, and execute on `/var/tmp/chmod_lab/secret.txt`. Set owner:group to `admin:admins`.

### Answer:
```bash
# Only the owner has full access; no one else can access
chmod 700 /var/tmp/chmod_lab/secret.txt

# Create the group
sudo groupadd admins

# Create the user and assign to group
sudo useradd -g admins admin

# Assign file ownership
chown admin:admins /var/tmp/chmod_lab/secret.txt
```

---

## Question 17: Allow the owner to read and write, while others can only read `/var/tmp/chmod_lab/document.txt`. Set owner:group to `student:students`.

### Answer:
```bash
# Owner can read and write; others can only read
chmod 644 /var/tmp/chmod_lab/document.txt

# Assign file ownership
chown student:students /var/tmp/chmod_lab/document.txt
```

---

## Question 18: Allow only the owner to read and write `/var/tmp/chmod_lab/private.key`. No one else should have access. Set owner:group to `tester:qa`.

### Answer:
```bash
# Owner can read/write; group and others have no access
chmod 600 /var/tmp/chmod_lab/private.key

# Assign file ownership
chown tester:qa /var/tmp/chmod_lab/private.key
```

---

## Question 19: Allow only the owner to read `/var/tmp/chmod_lab/readme.md`. Everyone else should have no access. Set owner:group to `analyst:finance`.

### Answer:
```bash
# Owner can read only; no one else has access
chmod 400 /var/tmp/chmod_lab/readme.md

# Assign file ownership
chown analyst:finance /var/tmp/chmod_lab/readme.md
```

---

## Question 20: Remove all permissions from `/var/tmp/chmod_lab/hidden.conf`. No one should be able to read, write, or execute it. Set owner:group to `backup:storage`.

### Answer:
```bash
# No permissions for anyone (completely restricted)
chmod 000 /var/tmp/chmod_lab/hidden.conf

# Assign file ownership
chown backup:storage /var/tmp/chmod_lab/hidden.conf
```

