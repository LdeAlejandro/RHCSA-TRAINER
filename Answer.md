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

## Question 26: Reset the root password on the local system by using GRUB recovery mode. Set the root password to hoppy and ensure the system can boot normally after the password reset.

### Answer

#### Access GRUB
1. Reboot the VM.
2. esc to access grub  
3. At the GRUB menu, highlight the default kernel and press **`e`** to edit.  
4. Find the line starting with `linux` or `linux16`.  
5. At the end of that line, add:

```bash
   rd.break 
   #or
   rw init=/bin/bash
   #or
   init=/bin/bash
   # Then press Ctrl + X 
 ```

If it drops you into switch_root:/#, run:
```bash
    mount -o remount,rw /sysroot
    chroot /sysroot
    passwd 
    # hoppy
    touch /.autorelabel
    exit
```

Option 2 – For RHEL 9+ (recommended if rd.break fails)
Replace everything after ro crashkernel=... with: rw init=/bin/bash


  #Example full line
  ```bash
  linux ($root)/vmlinuz-6.12.0-55.38.1.el10.0.x86_64 root=/dev/mapper/rhel_vbox-root rw init=/bin/bash
  ```
  
Then press Ctrl + X (or F10) to boot.

When you see the shell prompt:

bash-5.2#

```bash
mount -o remount,rw /
passwd
# set password to hoppy
touch /.autorelabel
exec /sbin/init
```
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
  echo 'echo "This task was easy!" >> /at-files/at.txt | at now +2 minutes' 

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

Configure a network connection named static-ens160 on interface ens160 with the following settings:

* IPv4 Address: 192.168.100.50/24
* Gateway: 192.168.100.1
* DNS Server: 8.8.8.8

Ensure the configuration persists after a system reboot.

```bash
  #Create the connection
  nmcli connection add type ethernet con-name static-ens160 ifname ens160 \
  ipv4.addresses 192.168.100.50/24 \
  ipv4.gateway 192.168.100.1 \
  ipv4.dns 8.8.8.8 \
  ipv4.method manual

  #Activate the connection
  nmcli connection up static-ens160

  #Verify configuration
  nmcli connection show static-ens160
```

---

## Question 48: Configure IPv6 Networking

Configure interface ens160 with the following IPv6 settings:

* IPv6 Address: 2001:db8::10/64
* Gateway: 2001:db8::1

Activate the configuration immediately.

```bash
  #Configure IPv6
  nmcli connection modify ens160 \
  ipv6.addresses 2001:db8::10/64 \
  ipv6.gateway 2001:db8::1 \
  ipv6.method manual

  #Activate changes
  nmcli connection up ens160

  #Verify
  ip -6 addr show ens160
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
  nmcli connection modify ens160 ipv4.dns "1.1.1.1 8.8.8.8"

  #Apply changes
  nmcli connection up ens160

  #Verify
  cat /etc/resolv.conf
  host redhat.com
```

---

## Question 51: Restore Network Connectivity

The network connection ens160 exists but is currently disconnected.

Restore network connectivity and ensure the connection activates automatically at system boot.

```bash
  #Bring connection up
  nmcli connection up ens160

  #Enable autoconnect
  nmcli connection modify ens160 connection.autoconnect yes

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

  #Verify
  journalctl --list-boots
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
  #Enable access to user home directories
  setsebool -P httpd_enable_homedirs on

  #Verify
  getsebool httpd_enable_homedirs
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
  #Create service file
  vim /etc/systemd/system/backup.service

  [Unit]
  Description=Backup Service

  [Service]
  ExecStart=/root/backup.sh

  [Install]
  WantedBy=multi-user.target

  #Reload systemd
  systemctl daemon-reload

  #Verify
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

## Question 65: Troubleshoot a Failed systemd Service

A systemd service has failed to start.

Identify the cause of the failure using systemd tools and relevant logs.

```bash
  #Check service status
  systemctl status SERVICE_NAME

  #View logs
  journalctl -xeu SERVICE_NAME

  #View service journal
  journalctl -u SERVICE_NAME
```

---

## Question 66: Extend an XFS Filesystem

An existing XFS filesystem requires additional storage.

Extend the filesystem without unmounting it and verify that the additional capacity is available.

```bash
  #Extend logical volume and filesystem
  lvextend -r -L +1G /dev/VGNAME/LVNAME

  #Verify
  df -h
```

---

## Question 67: Configure Firewall Access for Port 8080

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

## Question 68: Configure Firewall Access for NFS

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

## Question 69: Configure a Firewall Rich Rule

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

## Question 70: Create a User Validation Script

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

## Question 71: Create a File Validation Script

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
