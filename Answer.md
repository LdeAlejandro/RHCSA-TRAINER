## Question 1: On the local system, create a file named hello.txt in the current working directory. The file must contain the text "hello world". Save the file and ensure the content is written successfully.

### Answer: 

```bash
vim hello.txt
# type: hello world
# save & quit:
:wq
```

save the file

check with rhcsa-trainer eval

---

## Question 2: Configure SSH key-based authentication between the local system and a remote host. Ensure the user can log in to the remote system without being prompted for a password.

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

## Question 3: As an administrator, review recent system activity. Examine system logs, including authentication-related events, and verify the status of the SSH service using available log sources.

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

## Question 4: A file named "move me to document and copy me to backup" exists in /trainer/files. Move the file to /trainer/Documents and then create a copy of it in /trainer/DocumentBackup.

### Answer:

```bash
# 1. Move the file from 'files' to 'Documents'
mv "/trainer/files/move me to document and copy me to backup" /trainer/Documents/

# 2. Copy the file from 'Documents' to 'DocumentBackup'
cp "/trainer/Documents/move me to document and copy me to backup" /trainer/DocumentBackup/
```
---

## Question 5: On the system, identify all entries containing the string "Listen" in the Apache HTTP Server configuration file. Save the results to /root/web.txt.

### Answer:

```bash
# 1. Find the string "Listen" in /etc/httpd/conf/httpd.conf and save the output to /root/web.txt
 sudo grep Listen /etc/httpd/conf/httpd.conf > /root/web.txt

 #OR (if not from root user)
 sudo bash -c 'grep Listen /etc/httpd/conf/httpd.conf > /root/web.txt'
 ```
---

## Question 6: Create a directory named ~/vaults. Archive the entire /etc directory into a gzip-compressed tar file named etc_vault.tar.gz and store it in ~/vaults.

### Answer:
```bash
# Create directory
mkdir ~/vaults

#compresse files
tar -cvzf ~/vaults/etc_vault.tar.gz /etc
```
---

## Question 7: Create a directory named /shorts. Inside this directory create a file named file_a. Create a symbolic link named /file_b that points to /shorts/file_a.

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

## Question 8: A file named /hardfiles/file_data already exists on the system. Create a hard link named /file_c that references this file.

### Answer:
```bash
#create hardlink
ln /hardfiles/file_data /file_c
```
---

## Question 9: Create the directory /bigfiles. Locate all regular files under /usr that are larger than 3 MB and smaller than 10 MB, then copy them to /bigfiles.

### Answer:
```bash
#create directory
mkdir /bigfiles

#find and copy files to directory
find /usr -type f -size +3M -size -10M -exec cp {} /bigfiles \;


```
--- 

## Question 10: Create the directory /var/tmp/twenty. Locate all regular files under /etc that were modified more than 120 days ago and copy them to /var/tmp/twenty.

### Answer:
```bash
#create directory
mkdir /var/tmp/twenty

#find files
find /etc -type f -mtime +120 -exec cp {} /var/tmp/twenty \;
```
--- 

## Question 11: Create the directory /var/tmp/rhel-files. Locate all regular files under /tmp owned by the user rhel and copy them to /var/tmp/rhel-files.

### Answer:
```bash
#create directory
mkdir -p /var/tmp/rhel-files
#find files
find /tmp -type f -user rhel -exec cp {} /var/tmp/rhel-files \;
```
--- 

## Question 12: Locate all files named httpd.conf on the system and save their absolute paths to /root/httpd-paths.txt.

### Answer:
```bash
#find and copy the file to directory

find / -type f -name httpd.conf >> /root/httpd-paths.txt
#OR
sudo sh -c 'find / -type f -name httpd.conf >> /root/httpd-paths.txt'
```
--- 

## Question 13: Copy /etc/fstab to /var/tmp. Configure the copied file so that it is owned by root:root and cannot be executed by any user.

### Answer:
```bash
# Copy /etc/fstab to /var/tmp
cp /etc/fstab /var/tmp/

# Set file owner and group to root
chown root:root /var/tmp/fstab

# Set permissions to read/write for owner, read-only for others (no execute)
chmod 644 /var/tmp/fstab

```

## Question 14: Configure /var/tmp/chmod_lab/public.log so that it is owned by root:root and all users have full access to the file.

### Answer:
```bash
# Everyone can read, write, and execute this file
chmod 777 /var/tmp/chmod_lab/public.log

# Set file owner and group to root
chown root:root /var/tmp/chmod_lab/public.log
```

---

## Question 15: Configure /var/tmp/chmod_lab/script.sh with the following requirements:
- Owner: devops
- Group: devs
- Owner must have read, write, and execute permissions
- Group members must have read and execute permissions
- Other users must have read and execute permissions

Ensure the required user and group exist on the system.

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

## Question 16: Configure /var/tmp/chmod_lab/secret.txt with the following requirements:
- Owner: admin
- Group: admins
- Only the owner must have access to the file.
- The owner must be able to read, write, and execute the file.

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

## Question 17: Configure /var/tmp/chmod_lab/document.txt with the following requirements:
- Owner: student
- Group: students
- The owner must have read and write permissions.
- All other users must have read-only access.

### Answer:
```bash
# Owner can read and write; others can only read
chmod 644 /var/tmp/chmod_lab/document.txt

# Create the group
sudo groupadd students

# Create the user and assign to group
sudo useradd -g students student

# Assign file ownership
chown student:students /var/tmp/chmod_lab/document.txt
```

---

## Question 18: Configure /var/tmp/chmod_lab/private.key with the following requirements:
- Owner: tester
- Group: qa
- The owner must have read and write permissions.
- No other user should have access to the file.

### Answer:
```bash
# Owner can read/write; group and others have no access
chmod 600 /var/tmp/chmod_lab/private.key

# Create the group
sudo groupadd qa

# Create the user and assign to group
sudo useradd -g qa tester

# Assign file ownership
chown tester:qa /var/tmp/chmod_lab/private.key
```

---

## Question 19: Configure /var/tmp/chmod_lab/readme.md with the following requirements:
- Owner: analyst
- Group: finance
- The owner must have read-only access.
- No other user should have access to the file.

### Answer:
```bash
# Owner can read only; no one else has access
chmod 400 /var/tmp/chmod_lab/readme.md


# Create the group
sudo groupadd finance

# Create the user and assign to group
sudo useradd -g finance analyst

# Assign file ownership
chown analyst:finance /var/tmp/chmod_lab/readme.md
```

---

## Question 20: Configure /var/tmp/chmod_lab/hidden.conf with the following requirements:
- Owner: backup
- Group: storage
- No user should have any permissions on the file.

### Answer:
```bash
# No permissions for anyone (completely restricted)
chmod 000 /var/tmp/chmod_lab/hidden.conf

# Assign file ownership
chown backup:storage /var/tmp/chmod_lab/hidden.conf
```

---

## Question 21: Create a shell script named /root/find-files.sh that locates all regular files under /usr with a size between 30 KB and 50 KB. The script must save the results to /root/sized_files.txt.

### Answer:
```bash
# Create and open the script
vim /root/find-files.sh
#Inside the file:

#!/bin/bash
# This script finds files in /usr between 30KB and 50KB
# and writes the results to /root/sized_files.txt

find /usr -type f -size +30k -size -50k > /root/sized_files.txt

#Save and exit (:wq), then make it executable:

# add execution permissions to fiel
chmod +x /root/find-files.sh

#Test it:

/root/find-files.sh
cat /root/sized_files.txt
```
---

## Question 22: Create a local user account named noob with the password Aa7338!!. Configure the account so that the user is required to change the password at the next login.

### Answer:

```bash
sudo useradd noob
sudo passwd noob
# sugira/defina: Aa7338!!
# repita:        Aa7338!!
sudo passwd -e noob
```

---

## Question 23: Create a local user account named def4ult and assign the password Aa578!!??. After the account is created, change the password to C546#Ab!.

### Answer:

```bash
sudo useradd def4ult
sudo passwd def4ult
# defina:  Aa578!!??
# repita:  Aa578!!??

sudo passwd def4ult
# nova:    C546#Ab!
# repita:  C546#Ab!
```
---

## Question 24: Create a shell script named career.sh in the root user's home directory with the following behavior:

- When executed with the argument me, it must display:
  "Yes, I'm a Systems Engineer."
- When executed with the argument they, it must display:
  "Okay, they do cloud engineering."
- For invalid or missing arguments, it must display:
  "Usage: ./career.sh me|they"
- The script must have permissions set to 755.

### Answer:

```bash
cat > ~/career.sh <<'EOF'
#!/bin/bash
if [ "$1" = "me" ]; then
  echo "Yes, I'm a Systems Engineer."
elif [ "$1" = "they" ]; then
  echo "Okay, they do cloud engineering."
elif [ -z "$1" ]; then
  echo "Usage: ./career.sh me|they"
else
  echo "Usage: ./career.sh me|they"
fi
EOF

chmod 755 ~/career.sh

./career.sh

```

---

## Question 25: On node1, create shell scripts that automate user and group administration according to the requirements below.

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
```

### Answer:
```bash

# create groups txt file
vim groups.txt

hpc_admin:9090
hpc_managers:8080
sysadmin:7070

#save
```

```bash

# create shell script
vim create_groups.sh 
#!/bin/bash
while IFS=":" read group gid;
do
        echo "Creating group $group with GID $gid"
        groupadd -g "$gid" "$group";
done < groups.txt                              
#save

# add exec permisison
chmod +x create_groups.sh 
```

```bash

# create users.txt
vim users.txt

maryam:2030:hpc_admin,hpc_managers
adam:2040:sysadmin
jacob:2050:hpc_admin                            
#save
```

```bash

# create users shell script
vim create_users.sh

#!/bin/bash

while IFS=":" read user uid groups;
do
        echo "Creating user '$user' with UID '$uid' belonging to groups '$groups'";
        useradd -G "$groups" -u "$uid" "$user";
done < users.txt                          
#save

# add exec permisison
chmod +x create_users.sh
``` 

```bash

# create pass shell script
vim setpass.sh

#!/bin/bash

for user in maryam adam jacob;
do
        echo "Strong!2025" | passwd --stdin $user;
done                        
#save

# add exec permisison
chmod +x setpass.sh
```
Executar
```bash
./create_groups.sh 
./create_users.sh 
./setpass.sh 
```
---

# Question 26: Reset the Root Password Using GRUB Recovery Mode

Reset the root password on the local system by using GRUB recovery mode. Set the root password to **hoppy** and ensure the system boots normally afterward.

---

## Method 1 – Using `rd.break` (RHCSA Standard)

### Access GRUB

1. Reboot the system.
2. At the GRUB menu, highlight the default kernel.
3. Press **e** to edit the boot entry.
4. Find the line beginning with `linux`.
5. Append the following option to the end of the line:

```bash
rd.break
```

6. Press **Ctrl + X** to boot.

### Reset the Password

When the emergency shell appears:

```bash
mount -o remount,rw /sysroot
chroot /sysroot

passwd
# Enter: hoppy

touch /.autorelabel

exit
exit
```

The system will continue booting. During the next boot, SELinux will relabel files automatically.

---

## Method 2 – Using `init=/bin/bash`

### Access GRUB

1. Reboot the system.
2. At the GRUB menu, highlight the default kernel.
3. Press **e** to edit the boot entry.
4. Find the line beginning with `linux`.
5. Replace or append the boot options with:

```bash
rw init=/bin/bash
```

Example:

```bash
linux ($root)/vmlinuz-6.12.0-55.38.1.el10.x86_64 root=/dev/mapper/rhel-root rw init=/bin/bash
```

6. Press **Ctrl + X** to boot.

### Reset the Password

When the shell prompt appears:

```bash
mount -o remount,rw /

passwd
# Enter: hoppy

touch /.autorelabel

exec /sbin/init
```

The system will continue booting normally.

---

## RHCSA Exam Quick Reference

### Using `rd.break`

```bash
# In GRUB:
rd.break

# Boot:
Ctrl + X

mount -o remount,rw /sysroot
chroot /sysroot

passwd
# hoppy

touch /.autorelabel

exit
exit
```

### Using `init=/bin/bash`

```bash
# In GRUB:
rw init=/bin/bash

# Boot:
Ctrl + X

mount -o remount,rw /

passwd
# hoppy

touch /.autorelabel

exec /sbin/init
```

---

## Notes

- `rd.break` is the method most commonly associated with RHCSA objectives.
- `touch /.autorelabel` is required when SELinux is enabled to avoid authentication and labeling issues after the password change.
- `rd.break` uses `/sysroot` and requires `chroot /sysroot`.
- `init=/bin/bash` does **not** use `/sysroot` and does **not** require `chroot`.
---
## Question 27: On rhel-server, review the system tuning configuration and apply the recommended tuning profile. Configure SELinux to operate in permissive mode and ensure the appropriate network service is enabled and configured to start automatically at boot.

### check if tuned is intall and running change the tune to the recommended one

```bash
systemctl status tuned
#if necessary install
#dnf install tuned -y

sudo systemctl enable --now tuned

#check current tune 
tuned-adm active

#check tune recommendation
tuned-adm recommend

#check tune list
tuned-adm list

# change tune
sudo tuned-adm profile virtual-guest

#check current tune 
tuned-adm active

# Set SELinux to permissive at runtime
sudo setenforce 0

# Verify
getenforce

# Ensure network service is enabled and starts on boot If network.service exists
sudo systemctl enable --now network

# Otherwise (common on RHEL 8/9)
sudo systemctl enable --now NetworkManager
```

---

## Question 28: Configure SELinux so that the system operates in permissive mode after a reboot. Verify that the configuration persists across system restarts.

```bash
#check SELinux enforce mode
getenforce

#for persistant changes
sudo vim /etc/selinux/config

#look for the SELINUX line and change it
SELINUX=permissive

#restart to check if persistant
sudo reboot 

```
---

## Question 29: Ensure that the system networking service is enabled and configured to start automatically during system boot.

```bash
#check NetworkManager status
systemctl status NetworkManager

#enable it to be persistant
systemctl enable --now NetworkManager

```
---

## Question 30: Configure persistent systemd journal logging so that log data is retained across reboots.

```bash
#create directory
mkdir /var/log/journal

# Logs are now in the directory and not in ram
journalctl --flush

# check if file exist
ls /var/log/journal

#check if journal is using disk
journalctl --disk-usage

#check if the are .journla files
ls -R /var/log/journal
```
---

## Question 31:

A workload testing utility is installed on the system. Perform the following tasks:

- Start a stress-ng process with a niceness value of 19.
- Modify the running process so that its niceness value becomes 10.
- Terminate the process when finished.

```bash
#check if the app is installed
dnf list installed | grep stress-ng

#intall if needed
# Start stress-ng with niceness 19
nice -n 19 stress-ng --cpu 1 &

# Change niceness to 10
renice -n 10 -p $(pgrep stress-ng | head -1)

# Terminate the process
pkill stress-ng

#check resource with top
top

#extra you can kill process pressing "k" while in top view, you can use sigkill or 9
```
---

## Question 32:

Copy the file /etc/fstab to /var/tmp and configure access according to the following requirements:

- The file owner must be root.
- The file must not be executable by any user.
- User adam must have read and write access.
- User maryam must have no access.
- All other users must have read-only access.

```bash
#copy files
cp /etc/fstab /var/tmp

#set root as the owner
chown root: /var/tmp/fstab

#remove executable access from the files
chmod -x /var/tmp/fstab
 
#check permissions
ls -al /var/tmp/fstab
getfacl /var/tmp/fstab

#configure acess
 setfacl -m u:adam:rw- /var/tmp/fstab
 setfacl -m u:maryan:--- /var/tmp/fstab
 #others config
 setfacl -m o::r-- /var/tmp/fstab

 #check with
 getfacl /var/tmp/fstab
 ```
---

## Question 33: On rhel, create a file named rhel-file.txt in the current user's environment and securely transfer it to the home directory of user master-server on main-server.

```bash
#on rhel server
touch rhel-file.txt

#copy file to main server
scp -v rhel-file.txt master-server@192.168.15.14:/home/master-server
 ```
---

## Question 34: Create a logical volume named devops_lv using storage provided by /dev/sdc. The logical volume must be created from a volume group named devops_vg with physical extents of 20 MB. Configure the logical volume with 32 extents, create an ext4 filesystem on it, and mount it persistently at /mnt/devops_lv.

Check your work.

```bash
fdisk /dev/sdc

# add a new partition
n
#size
+650M

#save
w

#create physical volume
pvcreate /dev/sdc1

#create volumen group
vgcreate -s 20M devops_vg /dev/sdc1

#create logical volume
lvcreate -n devops_lv -l 32 devops_vg

#filesystem
mkfs.ext4 /dev/devops_vg/devops_lv

#create directory for mount
mkdir /mnt/devops_lv

# add it to be persistant in fstab
vim /etc/fstab

/dev/devops_vg/devops_lv                /mnt/devops_lv          ext4    defaults        0 0

#mount
mount -a
 ```
---

## Question 35: Using the disk /dev/sdd, create an 800 MB swap partition and configure the system so that the swap space is activated automatically after reboot. Verify that the swap space is available.

```bash
  #validar swap atual
  free -h

  #criar partiação swap
  fdisk /dev/sdd
  #criar partição
  n
  +800M
  w

  #ver partições
  lsblk

  #converter partiação criada para swap
  mkswap /dev/sdd2

  #fstab para montagem persistente
  vim /etc/fstab
  /dev/sdd2       swap    swap    defaults        0 0

  #apply changes
  mount -a
  swapon -a

  #check
   free -h
```
---
## Question 36:

On rhel-server, configure local storage according to the following requirements:

- Create a volume group named cloud_vg.
- Create a logical volume named cloud_lv from cloud_vg.
- The logical volume must have a size of 200 MB.
- Create an appropriate filesystem on the logical volume.
- Mount the filesystem and ensure it is available after a system reboot.

```bash
#create partition
fdisk /dev/sdb
n
p
1
ENTER
+270M
w

# create volume group
vgcreate cloud_vg /dev/sdbX

# create logical volume
lvcreate -L 200M -n cloud_lv cloud_vg

# create filesystem
mkfs.ext4 /dev/cloud_vg/cloud_lv

# create mount point
mkdir -p /mnt/cloud_lv

# make it persistent
vim /etc/fstab
/dev/cloud_vg/cloud_lv /mnt/cloud_lv ext4 defaults 0 0

# mount it
mount -a

# verify
df -h /mnt/cloud_lv
lsblk
```
---

## Question 37:

An existing logical volume named cloud_lv requires additional storage.

Resize cloud_lv so that its final size is 250 MB. A final size between 225 MB and 270 MB is acceptable. Ensure the filesystem is resized accordingly.

```bash
  #check logical volumes
  lvs
  #extend
  lvextend -L +50 /dev/cloud_vg/cloud_lv -r

  #lvs to check if it worked
  lvs
```
---

## Question 38: Cron Job Configuration

Configure a scheduled task for user rhel-user that records the following message in the system logs every 2 minutes:

```text
RHCSA Playlist Now Available
```

```bash
  #Check if crond is working
  systemctl status crond

  #if not
  systemctl --now enable crond

  #Check current user crontabs
  crontab -l

  #Check specific user crontabs
  crontab -l -u rhel

  #create crontab to run as an specific user
  crontab -e -u rhel

  #runs logger "RHCSA Playlist Now Available" every 2 minutes.
  */2 * * * * logger "RHCSA Playlist Now Available"
```
---

## Question 39:

Schedule a one-time job that writes the following text to /at-files/at.txt exactly 2 minutes from now:

```text
This task was easy!
```

```bash
  #Check if at is installed
  systemctl status atd
  #install and enable if need it

  #create directory
  mkdir /at-files

  #write te message in the file
  echo 'echo "This task was easy!" >> /at-files/at.txt'  | at now +2 minutes

  # Verify scheduled jobs
  atq

  # After 2 minutes, verify the file
  cat /at-files/at.txt

```
---

## Question 40: GRUB Bootloader Modification

Modify the GRUB bootloader configuration with the following requirements:

- Set GRUB_TIMEOUT to 10.
- Set GRUB_TIMEOUT_STYLE to hidden.
- Add the quiet kernel parameter to GRUB_CMDLINE_LINUX.
- Regenerate the GRUB configuration so the changes take effect.

```bash
  #Open the grub file
  vim /etc/default/grub
  # ADD LINES IN THE FILE IF NEED IT
    GRUB_TIMEOUT=10
    GRUB_TIMEOUT_STYLE=hidden
    GRUB_CMDLINE_LINUX=quiet

  #now we have to apply this new configs
  grub2-mkconfig -o /boot/grub2/grub.cfg
  #done
  
```
---

## Question 41: Enable Network Services

Ensure that the system network management service is enabled and automatically starts at boot.

```bash
  #Enable the service
  systemctl enable --now NetworkManager

  #check
  systemctl status NetworkManager
  
```
---

## Question 42: Firewall Rules

Configure the firewall to allow access to the following services permanently:

- SSH
- HTTP

Apply the configuration so that the changes take effect immediately.

```bash
  #check wich service and ports are allow
  firewall-cmd --list-all

  # add another rules to allow services
  firewall-cmd --add-service nfs --permanent
  firewall-cmd --add-service rpc-bind --permanent
  firewall-cmd --add-service ssh --permanent
  firewall-cmd --add-service http --permanent

  #reload firewall to apply
  firewall-cmd --reload
  
  #check enabled services
  firewall-cmd --list-services

  #check enabled ports
  firewall-cmd --list-ports

  #check permanent services
  firewall-cmd --permanent --list-services
```
---

## Question 43: Create Local Users and Groups

Create a group named sharegroup and configure the following user accounts:

- haruna must not be able to log in interactively and must not be a member of sharegroup.
- umar must be a member of sharegroup.
- adoga must have UID 4444 and be a member of sharegroup.

Configure the password persward for all users. Afterward, change the password of user adoga to perfect.

```bash
  #check if user group exist
  getent group sharegroup
  
  #Create group
  groupadd sharegroup

  # create a user with no login shell
  useradd -s /sbin/nologin haruna

  #you can check user id with
  id haruna

  # Create a user and add it to sharegroup
  useradd -G sharegroup umar
  id umar

  # Create user with specific id
  useradd -u 4444 -G sharegroup adoga
  id adoga

  #Create the passwords with a loop
  for user in haruna umar adoga; do echo "persward" | passwd --stdin $user; done

  #change the password for user adoga
  passwd adoga perfect


```
---

## Question 44: User Password Policies

Configure the system password policy to meet the following requirements:

- Passwords must have a minimum length of 8 characters.
- User passwords must expire after 30 days.

```bash
  #Edit the file for minumum length
  vim /etc/security/pwquality.conf
  minlen = 8

  #Edit the file for password expiration
  vim/etc/login.defs
  PASS_MAX_DAYS 30

  #done

```
---

## Question 45: User and Group Administration

Perform the following administrative tasks:

- Remove user umar from the sharegroup group.
- Delete the sharegroup group.
- Remove the user haruna and delete the user's home directory.

```bash
  #Check command for deletion
  man gpasswd

  #remove the user from the sharegroup
  gpasswd -d umar sharegroup

  #delete sharegroup
  groupdel sharegroup

  #delete user haruna with their home directory
  userdel -r haruna
```
---

## Question 46: Security Services Verification

Verify that firewalld and SELinux are enabled and active on the system. If firewalld is not running, configure it to start immediately and automatically at boot. Ensure SELinux is configured in enforcing mode.

```bash
systemctl status firewalld
systemctl is-active firewalld
systemctl is-enabled firewalld
systemctl enable --now firewalld
sudo vi /etc/selinux/config
SELINUX=enforcing
getenforce
```

---
## Question 47: Configure a Static IPv4 Network Connection

Configure a network connection named static-enp0s8 on interface enp0s8 with the following settings:

* IPv4 Address: 192.168.100.50/24
* Gateway: 192.168.100.1
* DNS Server: 8.8.8.8

Ensure the configuration persists after a system reboot.

```bash
  #Create the connection
  nmcli connection add type ethernet con-name static-enp0s8 ifname enp0s8 \
  ipv4.addresses 192.168.100.50/24 \
  ipv4.gateway 192.168.100.1 \
  ipv4.dns 8.8.8.8 \
  ipv4.method manual

  #Activate the connection
  nmcli connection up static-enp0s8

  #Verify configuration
  nmcli connection show static-enp0s8
```

---

## Question 48: Configure IPv6 Networking

Configure interface enp0s8 with the following IPv6 settings:

* IPv6 Address: 2001:db8::10/64
* Gateway: 2001:db8::1

Activate the configuration immediately.

```bash
  #Configure IPv6
  nmcli connection modify enp0s8 \
  ipv6.addresses 2001:db8::10/64 \
  ipv6.gateway 2001:db8::1 \
  ipv6.method manual

  #Activate changes
  nmcli connection up enp0s8

  #Verify
  ip -6 addr show enp0s8
```

---

## Question 49: Configure the System Hostname

Configure the system hostname as:

rhcsa-server.example.com

Ensure the hostname persists after a reboot.

```bash
  #Set hostname
  hostnamectl set-hostname rhcsa-server.example.com

  #Verify
  hostnamectl
```

---

## Question 50: Configure DNS Resolution

Configure the active network connection to use the following DNS servers:

* 1.1.1.1
* 8.8.8.8

Verify that hostname resolution functions correctly.

```bash
  #Identify active connection
  nmcli connection show --active

  #Configure DNS
  nmcli connection modify enp0s8 ipv4.dns "1.1.1.1 8.8.8.8"

  #Apply changes
  nmcli connection up enp0s8

  #Verify
  cat /etc/resolv.conf
  host redhat.com
```

---

## Question 51: Restore Network Connectivity

The network connection enp0s8 exists but is currently disconnected.

Restore network connectivity and ensure the connection activates automatically at system boot.

```bash
  #Bring connection up
  nmcli connection up enp0s8

  #Enable autoconnect
  nmcli connection modify enp0s8 connection.autoconnect yes

  #Verify
  nmcli connection show --active
```

---

## Question 52: Manage a CPU-Intensive Process

A process named stress-ng is consuming excessive CPU resources.

Locate the process and terminate it.

```bash
  #Locate process
  pgrep stress-ng
  ps aux | grep stress-ng

  #Terminate process
  pkill stress-ng

  #Verify
  pgrep stress-ng
```

---

## Question 53: Modify Process Priority

Start a process with a niceness value of 15.

Modify the running process so that its niceness value becomes 5.

```bash
  #Start process with niceness 15
  nice -n 15 sleep 1000 &

  #Locate PID
  ps -ef | grep sleep

  #Modify niceness
  renice 5 -p PID

  #Verify
  ps -o pid,ni,cmd -p PID
```

---

## Question 54: Identify High Memory Usage Processes

Identify the five processes currently consuming the most memory on the system.

```bash
  #Display top memory consumers
  ps aux --sort=-%mem | head -6
```

---

## Question 55: Review SSH Service Logs

Locate all messages generated by the sshd service during the current boot session.

```bash
  #Display sshd logs for current boot
  journalctl -b -u sshd
```

---

## Question 56: Review Recent System Logs

Locate all system log messages generated during the last 30 minutes.

```bash
  #Display logs from the last 30 minutes
  journalctl --since "30 minutes ago"
```

---

## Question 57: Configure Persistent Journaling

Configure the system so that journal logs are retained across system reboots.

```bash
  #Create persistent journal directory
  mkdir -p /var/log/journal

  #Restart journald
  systemctl restart systemd-journald

  #flush
  journalctl --flush

  #Verify
  journalctl --list-boots
  /var/log/journal
```

---

## Question 58: Configure Time Synchronization

Configure the system to synchronize time with pool.ntp.org.

Verify that time synchronization is functioning correctly.

```bash
  #Edit chrony configuration
  vim /etc/chrony.conf

  pool pool.ntp.org iburst

  #Restart chronyd
  systemctl restart chronyd

  #Verify synchronization
  chronyc sources
  chronyc tracking
```

---

## Question 59: Configure a Custom NTP Source

Configure the system to use the following host as its NTP source:

server1.example.com

Verify that the configuration is active.

```bash
  #Edit chrony configuration
  vim /etc/chrony.conf

  server server1.example.com iburst

  #Restart chronyd
  systemctl restart chronyd

  #Verify
  chronyc sources
  chronyc tracking
```

---

## Question 60: Configure SELinux for Apache Home Directories

Configure SELinux so that the Apache web server is permitted to access user home directories.

Ensure the configuration persists across reboots.

```bash
  #validar bools disponiveis
  getsebool -a | grep httpd
  #or
  semanage boolean -l | grep httpd

  # Verify SELinux is enabled
  getenforce

  # Enable access to user home directories
  setsebool -P httpd_enable_homedirs on

  # Verify the SELinux boolean
  getsebool httpd_enable_homedirs

  # Alternative verification
  getsebool -a | grep httpd_enable_homedirs

  # Verify persistent boolean configuration
  semanage boolean -l | grep httpd_enable_homedirs
```

---

## Question 61: Configure SELinux for Custom Web Content

Create the directory:

/webdata

Configure SELinux so that the Apache web server can permanently serve content from this directory.

```bash
  #Create directory
  mkdir /webdata

  #Configure SELinux context
  semanage fcontext -a -t httpd_sys_content_t "/webdata(/.*)?"

  #Apply context
  restorecon -Rv /webdata

  #Verify
  ls -Zd /webdata
```

---

## Question 62: Configure Apache on Port 8080

Configure the Apache web server to listen on TCP port 8080.

Adjust SELinux settings as required to permit access to this port.

```bash
  #Configure Apache
  vim /etc/httpd/conf/httpd.conf

  Listen 8080

  #Allow port in SELinux
  semanage port -a -t http_port_t -p tcp 8080

  #Restart Apache
  systemctl restart httpd

  #Verify
  ss -tlnp | grep 8080
```

---

## Question 63: Create a Custom systemd Service

Create a custom systemd service named backup.service.

The service must execute the script:

/root/backup.sh

Ensure the service definition is correctly recognized by systemd.

```bash
# Create the script
vim /root/backup.sh

#!/bin/bash
echo "Backup completed"

# Make the script executable
chmod +x /root/backup.sh

# Create the service file
vim /etc/systemd/system/backup.service

[Unit]
Description=Backup Service

[Service]
Type=oneshot
ExecStart=/root/backup.sh

[Install]
WantedBy=multi-user.target

# Reload systemd configuration
systemctl daemon-reload

# Verify the service definition
systemctl status backup.service

# Test the service
systemctl start backup.service
systemctl status backup.service
```
---

## Question 64: Enable a systemd Service

Configure backup.service so that it starts automatically during system boot.

Verify that the service is enabled.

```bash
  #Enable service
  systemctl enable backup.service

  #Verify
  systemctl is-enabled backup.service
```

---

## Question 65: Extend an XFS Filesystem

An existing XFS filesystem is mounted on "/mnt/xfs_lv".

Increase the size of the filesystem by 200 MB without unmounting it and ensure the additional capacity is available immediately.

```bash
   # Verify current size
  lvs
  df -h /mnt/xfs_lv

  # Extend the logical volume
  lvextend -L +200M /dev/xfs_vg/xfs_lv

  # Grow the XFS filesystem online
  xfs_growfs /mnt/xfs_lv

  # Verify
  lvs
  df -h /mnt/xfs_lv
```

---

## Question 66: Configure Firewall Access for Port 8080

Configure the firewall to permanently allow access to TCP port 8080.

Apply the configuration immediately.

```bash
  #Allow TCP port 8080
  firewall-cmd --permanent --add-port=8080/tcp

  #Apply configuration
  firewall-cmd --reload

  #Verify
  firewall-cmd --list-ports
```

---

## Question 67: Configure Firewall Access for NFS

Configure the firewall to permanently allow access to the NFS service.

Verify that the service is permitted through the firewall.

```bash
  #Allow NFS service
  firewall-cmd --permanent --add-service=nfs

  #Apply configuration
  firewall-cmd --reload

  #Verify
  firewall-cmd --list-services
```

---

## Question 68: Configure a Firewall Rich Rule

Configure a firewall rich rule that permits SSH access only from the following network:

192.168.100.0/24

Apply the configuration immediately.

```bash
  #Add rich rule
  firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" source address="192.168.100.0/24" service name="ssh" accept'

  #Apply configuration
  firewall-cmd --reload

  #Verify
  firewall-cmd --list-rich-rules
```

---

## Question 69: Create a User Validation Script

Create a shell script that receives a username as an argument.

The script must behave as follows:

* If the user exists, display:
  User Exists
* If the user does not exist, display:
  User Not Found

The script must be executable.

```bash
  #Create script
  vim usercheck.sh

  #!/bin/bash

  if id "$1" &>/dev/null; then
      echo "User Exists"
  else
      echo "User Not Found"
  fi

  #Make executable
  chmod 755 usercheck.sh
```

---

## Question 70: Create a File Validation Script

Create a shell script that accepts multiple filenames as command-line arguments.

The script must display only the filenames that currently exist on the system.

The script must be executable.

```bash
  #Create script
  vim filecheck.sh

  #!/bin/bash

  for file in "$@"; do
      if [ -e "$file" ]; then
          echo "$file"
      fi
  done

  #Make executable
  chmod 755 filecheck.sh
```
---
## Question 71: Configure File Permissions

Configure a file `/secure/passwd-tool` to meet the following requirements:

- The file is owned by `root`.
- The group owner is `root`.
- Users executing the file obtain the privileges of the file owner.
- Configure the appropriate permissions.

Verify your work.

```bash
  #Create directory and file
  mkdir -p /secure
  touch /secure/passwd-tool

  #Configure ownership
  chown root:root /secure/passwd-tool

  #Configure SUID and permissions
  chmod 4755 /secure/passwd-tool

  #Verify
  ls -l /secure/passwd-tool
  stat -c '%A %a %U:%G' /secure/passwd-tool
```

---

## Question 72: Configure a Shared Directory

Create the directory `/shared-devs`

Configure the directory to meet the following requirements:

- The group owner must be `devs`.
- Members of the `devs` group must be able to create files in the directory.
- Files and directories created under `/shared-devs` must inherit the directory's group ownership.

Verify your work.

```bash
  #Create group if necessary
  groupadd devs

  #Create directory
  mkdir -p /shared-devs

  #Configure group ownership
  chown root:devs /shared-devs

  #Configure SGID and group access
  chmod 2770 /shared-devs

  #Verify
  ls -ld /shared-devs
  stat -c '%A %a %U:%G' /shared-devs
```

---

## Question 73: Configure a Directory with Sticky Bit

Create a directory named `/public-share`.

Configure the directory so that:

* All users can create files inside it.
* Users cannot delete files owned by other users.

Verify your work.

```bash
  #Create directory
  mkdir -p /public-share

  #Give all users full access and enable sticky bit
  chmod 1777 /public-share

  #Verify
  ls -ld /public-share
  stat -c '%A %a' /public-share
```

---

## Question 74: Locate Files with SUID Permission

Locate all regular files on the system that have the SUID permission enabled.

Save their absolute paths to `/root/suid-files.txt`.

```bash
  #Find regular files with SUID enabled
  find / -type f -perm -4000 2>/dev/null > /root/suid-files.txt

  #Verify
  cat /root/suid-files.txt
```

---

## Question 75: Locate Files with SGID Permission

Locate all regular files on the system that have the SGID permission enabled.

Save their absolute paths to `/root/sgid-files.txt`.

```bash
  #Find regular files with SGID enabled
  find / -type f -perm -2000 2>/dev/null > /root/sgid-files.txt

  #Verify
  cat /root/sgid-files.txt
```

---

## Question 76: Configure ACL Permissions on fstab

Copy `/etc/fstab` to `/acl-lab/fstab`.

Configure the following permissions:

* The owner must have read and write access.
* The group must have read-only access.
* User `adam` must have read and write access.
* User `maryam` must have no access.
* All other users must have read-only access.

Use ACLs where required.

```bash
  #Create users if necessary
  useradd adam
  useradd maryam

  #Create directory and copy file
  mkdir -p /acl-lab
  cp /etc/fstab /acl-lab/fstab

  #Configure standard permissions
  chown root:root /acl-lab/fstab
  chmod 644 /acl-lab/fstab

  #Configure ACL entries
  setfacl -m u:adam:rw- /acl-lab/fstab
  setfacl -m u:maryam:--- /acl-lab/fstab
  setfacl -m m::rw- /acl-lab/fstab
  setfacl -m o::r-- /acl-lab/fstab

  #Verify
  getfacl /acl-lab/fstab
```

---

## Question 77: Configure an ACL for a Specific User

Create the file `/project/report.txt`.

Configure the following permissions:

* The owner must have read and write access.
* The group must have read-only access.
* User `jacob` must have read and write access through an ACL.
* Other users must have no access.

```bash
  #Create user if necessary
  useradd jacob

  #Create directory and file
  mkdir -p /project
  touch /project/report.txt

  #Configure standard permissions
  chmod 640 /project/report.txt

  #Give jacob read and write access
  setfacl -m u:jacob:rw- /project/report.txt
  setfacl -m m::rw- /project/report.txt

  #Verify
  getfacl /project/report.txt
```

---

## Question 78: Configure a Default ACL

Create the directory `/projects`.

Configure a default ACL so that user `adam` automatically receives read and write access to newly created files and directories inside `/projects`.

```bash
  #Create user if necessary
  useradd adam

  #Create directory
  mkdir -p /projects

  #Allow adam to access the existing directory
  setfacl -m u:adam:rwx /projects

  #Configure default ACL
  setfacl -m d:u:adam:rwx /projects

  #Verify default ACL
  getfacl /projects

  #Test inheritance
  touch /projects/test-file
  mkdir /projects/test-directory

  getfacl /projects/test-file
  getfacl /projects/test-directory
```

---

## Question 79: Configure Default Group ACL Permissions

Create the directory `/shared-reports`.

Configure the following default ACL permissions:

* Members of group `finance` must receive read and write access.
* Other users must receive no access.

The permissions must apply automatically to new files and directories created inside `/shared-reports`.

```bash
  #Create group if necessary
  groupadd finance

  #Create directory
  mkdir -p /shared-reports

  #Configure group ownership and SGID
  chown root:finance /shared-reports
  chmod 2770 /shared-reports

  #Configure access ACL on the existing directory
  setfacl -m g:finance:rwx /shared-reports
  setfacl -m o::--- /shared-reports

  #Configure default ACL
  setfacl -m d:g:finance:rwx /shared-reports
  setfacl -m d:o::--- /shared-reports

  #Verify
  getfacl /shared-reports
```

---

## Question 80: Back Up ACL Configuration

Create a backup of the ACL configuration for `/projects`.

Save the ACL backup to `/root/projects.acl`.

```bash
  #Back up ACL configuration recursively
  getfacl -R /projects > /root/projects.acl

  #Verify
  cat /root/projects.acl
```

To restore the ACL backup:

```bash
  setfacl --restore=/root/projects.acl
```

---

## Question 81: Configure a User Cron Job

Configure a cron job for user `student`.

The job must execute the following command every day at 01:30:

```bash
logger "daily backup"
```

```bash
  #Create user if necessary
  useradd student

  #Edit student's crontab
  crontab -u student -e

  #Add this entry
  30 1 * * * /usr/bin/logger "daily backup"

  #Verify
  crontab -u student -l
```

---

## Question 82: Configure a Root Cron Job

Configure a cron job for root.

The job must execute the following command every Sunday at 02:00:

```bash
touch /root/cron-success
```

```bash
  #Edit root's crontab
  crontab -e

  #Add this entry
  0 2 * * 0 /usr/bin/touch /root/cron-success

  #Verify
  crontab -l
```

---

## Question 83: Configure a Cron Job Every Five Minutes

Configure a cron job that runs every five minutes.

The job must append the current date to `/var/log/cron-test.log`.

```bash
  #Edit root's crontab
  crontab -e

  #Add this entry
  */5 * * * * /usr/bin/date >> /var/log/cron-test.log

  #Verify
  crontab -l

  #Ensure crond is enabled and running
  systemctl enable --now crond
  systemctl status crond
```

---

## Question 84: Configure Cron Access Control

Configure cron access so that:

* User `maryam` is allowed to create cron jobs.
* User `jacob` is denied access to cron.

```bash
  #Create users if necessary
  useradd maryam
  useradd jacob

  #When cron.allow exists, only listed users may use cron
  printf 'root\nmaryam\n' > /etc/cron.allow

  #Explicitly record jacob as denied
  echo 'jacob' > /etc/cron.deny

  #Secure the files
  chmod 600 /etc/cron.allow /etc/cron.deny
  chown root:root /etc/cron.allow /etc/cron.deny

  #Verify
  cat /etc/cron.allow
  cat /etc/cron.deny
```

---

## Question 85: Create a Daily Systemd Timer

Create a systemd service named `hello.service`.

The service must execute:

```bash
/usr/bin/logger "hello folks"
```

Create a timer named `hello.timer` that runs the service every day at 03:00.

```bash
  #Create service unit
  vim /etc/systemd/system/hello.service

  [Unit]
  Description=Write hello folks to the journal

  [Service]
  Type=oneshot
  ExecStart=/usr/bin/logger "hello folks"
```

```bash
  #Create timer unit
  vim /etc/systemd/system/hello.timer

  [Unit]
  Description=Run hello.service every day at 03:00

  [Timer]
  OnCalendar=*-*-* 03:00:00
  Persistent=true
  Unit=hello.service

  [Install]
  WantedBy=timers.target
```

```bash
  #Reload systemd and enable timer
  systemctl daemon-reload
  systemctl enable --now hello.timer

  #Verify
  systemctl status hello.timer
  systemctl list-timers hello.timer
```

---

## Question 86: Create a Systemd Timer That Runs Every Ten Minutes

Create a service named `timer-test.service`.

The service must append the current date and time to `/var/log/timer-test.log`.

Create a timer named `timer-test.timer` that executes the service every ten minutes.

```bash
  #Create service unit
  vim /etc/systemd/system/timer-test.service

  [Unit]
  Description=Write the current date to a log file

  [Service]
  Type=oneshot
  ExecStart=/usr/bin/bash -c '/usr/bin/date >> /var/log/timer-test.log'
```

```bash
  #Create timer unit
  vim /etc/systemd/system/timer-test.timer

  [Unit]
  Description=Run timer-test.service every ten minutes

  [Timer]
  OnBootSec=10min
  OnUnitActiveSec=10min
  Unit=timer-test.service

  [Install]
  WantedBy=timers.target
```

```bash
  #Reload and enable timer
  systemctl daemon-reload
  systemctl enable --now timer-test.timer

  #Verify
  systemctl list-timers timer-test.timer
  systemctl status timer-test.timer
```

---

## Question 87: Create a User Systemd Timer

Create a user service and timer for user `chisha`.

The timer must run from Monday through Friday at 02:00 and execute:

```bash
/usr/bin/logger "user timer"
```

```bash
  #Enable user services while chisha is logged out
  loginctl enable-linger chisha

  #login as chisha in localhost
  ssh chisha@localhost

  #Create user systemd directory
  mkdir -p ~/.config/systemd/user
```

```bash
  #Create user service
  vim ~/.config/systemd/user/hello-user.service

  [Unit]
  Description=Write a user timer message to the journal

  [Service]
  Type=oneshot
  ExecStart=/usr/bin/logger "user timer"
```

```bash
  #Create user timer
  vim ~/.config/systemd/user/hello-user.timer

  [Unit]
  Description=Run hello-user.service from Monday through Friday

  [Timer]
  OnCalendar=Mon..Fri *-*-* 02:00:00
  Persistent=true
  Unit=hello-user.service

  [Install]
  WantedBy=timers.target
```

```bash
  #Reload user systemd and enable timer
  systemctl --user daemon-reload
  systemctl --user enable --now hello-user.timer

  #Verify
  systemctl --user status hello-user.timer
  systemctl --user list-timers hello-user.timer
```

---

## Question 88: Query an Installed RPM Package

Determine whether the `httpd` package is installed.

Save its package name, version, and release to `/root/httpd-version.txt`.

```bash
  #Check whether httpd is installed
  rpm -q httpd

  #Save package information
  rpm -q --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' httpd \
    > /root/httpd-version.txt

  #Verify
  cat /root/httpd-version.txt
```

---

## Question 89: Determine Which RPM Owns a File

Use the RPM database to determine which installed package provides `/usr/bin/ssh`.

Save the package name to `/root/ssh-package.txt`.

```bash
  #Query the package that owns the file
  rpm -qf /usr/bin/ssh > /root/ssh-package.txt

  #Verify
  cat /root/ssh-package.txt
```

---

## Question 90: Install a Local RPM Package

Install the local RPM package located at `/root/packages/demo-package.rpm`.

Verify that the package is installed.

```bash
  #Inspect the RPM package
  rpm -qpi /root/packages/demo-package.rpm

  #Get the package name
  PACKAGE_NAME=$(rpm -qp --qf '%{NAME}' /root/packages/demo-package.rpm)

  #Install the package and resolve dependencies
  dnf install -y /root/packages/demo-package.rpm

  #Verify installation
  rpm -q "$PACKAGE_NAME"
```

---

## Question 91: Configure a User Flatpak Repository

Install Flatpak on the system.

Configure the Flathub repository for user `chisha` only.

The repository must be named `userrepo`.

```bash
  #Install Flatpak system-wide
  dnf install -y flatpak

  #Add Flathub for chisha only
  runuser -u chisha -- flatpak remote-add \
    --user \
    --if-not-exists \
    userrepo \
    https://dl.flathub.org/repo/flathub.flatpakrepo

  #Verify user repository
  runuser -u chisha -- flatpak remotes --user
```

---

## Question 92: Install a User Flatpak Application

Install `org.gimp.GIMP` for user `chisha` only.

```bash
  #Install GIMP from the user repository
  runuser -u chisha -- flatpak install \
    --user \
    -y \
    userrepo \
    org.gimp.GIMP

  #Verify
  runuser -u chisha -- flatpak list --user
  runuser -u chisha -- flatpak info --user org.gimp.GIMP
```

---

## Question 93: Add a User to Supplementary Groups

Create a user named `developer`.

Create the groups `devops` and `qa`.

Add `developer` to both groups without removing existing supplementary group memberships.

```bash
  #Create groups
  groupadd devops
  groupadd qa

  #Create user
  useradd developer

  #Append supplementary groups
  usermod -aG devops,qa developer

  #Verify
  id developer
  groups developer
```

---

## Question 94: Rename a Group

Rename the group `developers` to `engineering`.

Preserve the existing GID and memberships.

```bash
  #Create the original group if necessary
  groupadd developers

  #Check the original GID
  getent group developers

  #Rename the group
  groupmod -n engineering developers

  #Verify
  getent group engineering
```

---

## Question 95: Modify a User Account

Modify user `developer` so that:

* The UID is `4500`.
* The login shell is `/bin/bash`.
* The home directory is `/home/developer-new`.
* Existing home directory contents are moved to the new location.

```bash
  #Modify UID, shell and home directory
  usermod \
    -u 4500 \
    -s /bin/bash \
    -d /home/developer-new \
    -m \
    developer

  #Verify
  id developer
  getent passwd developer
  ls -ld /home/developer-new
```

---

## Question 96: Find Files Owned by a User

Locate all regular files under `/var` owned by user `developer`.

Copy the matching files to `/root/developer-files`.

Preserve their original filenames and directory structure.

```bash
  #Create destination directory
  mkdir -p /root/developer-files

  #Find and copy files while preserving their paths
  find /var -type f -user developer \
    -exec cp --parents {} /root/developer-files \;

  #Verify
  find /root/developer-files -type f
```

---

## Question 97: Locate Directories with SGID Permission

Locate all directories on the system that have the SGID permission enabled.

Save their absolute paths to `/root/sgid-directories.txt`.

```bash
  #Find directories with SGID enabled
  find / -type d -perm -2000 2>/dev/null \
    > /root/sgid-directories.txt

  #Verify
  cat /root/sgid-directories.txt
```

---

## Question 98: Locate Files with SUID or SGID Permissions

Locate all regular files on the system that have either the SUID or SGID permission enabled.

Save their absolute paths to `/root/special-permissions.txt`.

```bash
  #Find files with SUID or SGID enabled
  find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null \
    > /root/special-permissions.txt

  #Alternative using either special permission bit
  find / -type f -perm /6000 2>/dev/null \
    > /root/special-permissions.txt

  #Verify
  cat /root/special-permissions.txt
```

---

## Question 99: Reduce an ext4 Logical Volume

An ext4 logical volume exists at `/dev/data_vg/data_lv`.

Reduce the filesystem and logical volume from 500 MB to 300 MB.

Ensure the filesystem remains usable.

```bash
  #Verify the filesystem type and current size
  lsblk -f /dev/data_vg/data_lv
  lvs /dev/data_vg/data_lv

  #Identify the mount point
  findmnt /dev/data_vg/data_lv

  #Save the mount point
  MOUNTPOINT=$(findmnt -n -o TARGET /dev/data_vg/data_lv)

  #Unmount the filesystem
  umount "$MOUNTPOINT"

  #Check the ext4 filesystem
  e2fsck -f /dev/data_vg/data_lv

  #Reduce the filesystem first
  resize2fs /dev/data_vg/data_lv 300M

  #Reduce the logical volume
  lvreduce -L 300M /dev/data_vg/data_lv

  #Check the filesystem again
  e2fsck -f /dev/data_vg/data_lv

  #Mount it again using /etc/fstab
  mount "$MOUNTPOINT"

  #Verify
  lvs /dev/data_vg/data_lv
  df -h "$MOUNTPOINT"
```

---

## Question 100: Safely Determine Whether a Logical Volume Can Be Reduced

A logical volume exists at `/dev/archive_vg/archive_lv`.

Determine the filesystem type.

If the filesystem supports reduction, reduce the logical volume to 400 MB while preserving the data.

If the filesystem does not support reduction, do not perform a destructive operation.

```bash
  #Determine the filesystem type
  lsblk -f /dev/archive_vg/archive_lv
  blkid /dev/archive_vg/archive_lv

  #Save filesystem type
  FSTYPE=$(lsblk -n -o FSTYPE /dev/archive_vg/archive_lv)

  echo "$FSTYPE"
```

For an ext4 filesystem:

```bash
  #Identify and save mount point
  MOUNTPOINT=$(findmnt -n -o TARGET /dev/archive_vg/archive_lv)

  #Unmount filesystem
  umount "$MOUNTPOINT"

  #Check filesystem
  e2fsck -f /dev/archive_vg/archive_lv

  #Reduce filesystem first
  resize2fs /dev/archive_vg/archive_lv 400M

  #Reduce logical volume
  lvreduce -L 400M /dev/archive_vg/archive_lv

  #Mount filesystem again
  mount "$MOUNTPOINT"

  #Verify
  lvs /dev/archive_vg/archive_lv
  df -h "$MOUNTPOINT"
```

For an XFS filesystem:

```bash
  #XFS filesystems cannot be reduced
  echo "XFS does not support shrinking. No reduction performed."

  #Verify that no destructive operation was performed
  lvs /dev/archive_vg/archive_lv
```

---

## Question 101: Allow SSH from a Specific Network

Configure a permanent firewall rich rule that permits SSH access only from `192.168.100.0/24`.

Apply the configuration immediately.

```bash
  #Remove the globally allowed SSH service
  firewall-cmd --permanent --remove-service=ssh

  #Add source-specific SSH rich rule
  firewall-cmd --permanent \
    --add-rich-rule='rule family="ipv4" source address="192.168.100.0/24" service name="ssh" accept'

  #Apply configuration
  firewall-cmd --reload

  #Verify
  firewall-cmd --list-services
  firewall-cmd --list-rich-rules
```

---

## Question 102: Reject HTTP from a Specific Host

Configure a permanent firewall rich rule that rejects HTTP access from `192.168.100.50`.

Apply the configuration immediately.

```bash
  #Add rich rule
  firewall-cmd --permanent \
    --add-rich-rule='rule family="ipv4" source address="192.168.100.50" service name="http" reject'

  #Apply configuration
  firewall-cmd --reload

  #Verify
  firewall-cmd --list-rich-rules
```

---

## Question 103: Allow HTTPS from a Specific Network

Configure a permanent firewall rich rule that permits HTTPS access from `192.168.100.0/24`.

Apply the configuration immediately.

```bash
  #Add rich rule
  firewall-cmd --permanent \
    --add-rich-rule='rule family="ipv4" source address="192.168.100.0/24" service name="https" accept'

  #Apply configuration
  firewall-cmd --reload

  #Verify
  firewall-cmd --list-rich-rules
```

---

## Question 104: Log and Drop SSH Attempts

Configure a permanent firewall rich rule that logs and drops all SSH connection attempts from `10.10.10.0/24`.

Use the log prefix `blocked-ssh`.

Apply the configuration immediately.

```bash
  #Add rich rule with logging and rate limiting
  firewall-cmd --permanent \
    --add-rich-rule='rule family="ipv4" source address="10.10.10.0/24" service name="ssh" log prefix="blocked-ssh" limit value="5/m" drop'

  #Apply configuration
  firewall-cmd --reload

  #Verify
  firewall-cmd --list-rich-rules

  #Check logged messages
  journalctl -k | grep blocked-ssh
```

---

## Question 105: Allow Port 8080 from a Specific Network

Configure a permanent firewall rich rule that allows TCP traffic to port `8080` only from `172.16.50.0/24`.

Apply the configuration immediately.

```bash
  #Remove port 8080 if it is globally allowed
  firewall-cmd --permanent --remove-port=8080/tcp

  #Add source-specific rich rule
  firewall-cmd --permanent \
    --add-rich-rule='rule family="ipv4" source address="172.16.50.0/24" port port="8080" protocol="tcp" accept'

  #Apply configuration
  firewall-cmd --reload

  #Verify
  firewall-cmd --list-ports
  firewall-cmd --list-rich-rules
```

---
