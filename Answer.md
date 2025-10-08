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