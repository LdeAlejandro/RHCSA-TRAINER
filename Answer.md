## Question 1: Use vim to create and save a file hello.txt containing 'hello world'

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
tar -cvzf ~/vaults/etc_vault.tar.gz /etc
```
---
## Question 7: (root directory / ) File Links - Create a file file_a in shorts directory create soft link file_b pointing to file_a

### Answer:
```bash
# Create directory
mkdir /shorts

#Create file
touch /shorts/file_a

#create softlink
ln -s /shorts/file_a file_b

## if the link was created and is having error sudo 
ln -snf /shorts/file_a file_b

```
---
## Question 8: File Links - (root directory / ) Create a hard link of the file in hardfiles directory to file_c

### Answer:
```bash
#create hardlink
ln /hardfiles/file_data file_c
```
---
## Question 9:(root directory / ) Find files in /usr that are greater than 3MB but < 10MB and copy them to /bigfiles directory.

### Answer:
```bash
#create directory
mkdir /bigfiles

#find and copy files to directory
find /usr -type f -size +3M -size -10M -exec cp {} /bigfiles \;


```
--- 

## Question 10: Find files in /etc modified more than 120 days ago and copy them to /var/tmp/twenty/

### Answer:
```bash
#create directory
mkdir /var/tmp/twenty

#find files
find /etc -type f -mtime +120 -exec cp {} /var/tmp/twenty \;
```
--- 

## Question 11:Find all /tmp files owned by user rhel and copy them to /var/tmp/rhel-files.

### Answer:
```bash
#create directory
mkdir -p /var/tmp/rhel-files
#find files
find /tmp -type f -user rhel -exec cp {} /var/tmp/rhel-files \;
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

## Question 16: Allow only the owner to read, write, and execute on `/var/tmp/chmod_lab/secret.txt`. Set ownership for the file owner:group to `admin:admins`.

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

# Create the group
sudo groupadd students

# Create the user and assign to group
sudo useradd -g students student

# Assign file ownership
chown student:students /var/tmp/chmod_lab/document.txt
```

---

## Question 18: Allow only the owner to read and write `/var/tmp/chmod_lab/private.key`. No one else should have access. Set owner:group to `tester:qa`.

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

## Question 19: Allow only the owner to read `/var/tmp/chmod_lab/readme.md`. Everyone else should have no access. Set owner:group to `analyst:finance`.

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

## Question 20: Remove all permissions from `/var/tmp/chmod_lab/hidden.conf`. No one should be able to read, write, or execute it. Set owner:group to `backup:storage`.

### Answer:
```bash
# No permissions for anyone (completely restricted)
chmod 000 /var/tmp/chmod_lab/hidden.conf

# Assign file ownership
chown backup:storage /var/tmp/chmod_lab/hidden.conf
```
---
## Question 21: Create a shell script /root/find-files.sh that finds files in /usr between 30KB and 50KB and saves results to /root/sized_files.txt.

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

## Question 22: Create an user with the name of "noob" password: Aa7338!! and configure so the user has to change the password on the next login.

### Answer:

```bash
sudo useradd noob
sudo passwd noob
# sugira/defina: Aa7338!!
# repita:        Aa7338!!
sudo passwd -e noob
```

---

## Question 23: Create an user with the name "def4ult" with the password: Aa578!!?? and change the password to C546#Ab!

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


## Question 24: Create a shell script that Outputs "Yes, I’m a Systems Engineer." when run with ./career.sh me , Outputs "Okay, they do cloud engineering." when run with ./career.sh they ,Outputs "Usage: ./career.sh me|they" for invalid/empty arguments, the file must has 755 permission

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

## Question 25: Write shell scripts (create_groups.sh, create_users.sh, setpass.sh) on node1 that perform the following tasks:

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
jacob:2050:hpc_admin

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

## Question 26: In a new VM Reset Root Password via GRUB

**Task:**  
Break into `node2` and set a new root password to **hoppy**.

---

### Answer

#### Access GRUB
1. Reboot the VM.  
2. At the GRUB menu, highlight the default kernel and press **`e`** to edit.  
3. Find the line starting with `linux` or `linux16`.  
4. At the end of that line, add:

```bash
   rd.break 
   #or
   rw init=/bin/bash
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

## Question 27: Tuning Profile Configuration and SELINUX

- Check the current recommended tuning profile.
- Put SELinux in permissive mode on master-server.
- On rhel-server ensure network service is enabled and starts on boot.


### check on both server is tuned is intall and running change the tune to the recommended one

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

```

---

## Question 28: Put SELinux in permissive mode on master-server.


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

## Question 29: On node1 ensure network service is enabled and starts on boot.


```bash
#check NetworkManager status
systemctl status NetworkManager

#enable it to be persistant
systemctl enable --now NetworkManager


```
---

## Question 30: Configure persistant journalist in both server

```bash
#create directory
mkdir /var/log/journal

# Logs are now in the directory and not in ram
journalctl --flush

# check if file exist
ls /var/log/journal


```
---

## Question 31: 
- Start a stress-ng process on node1 with a niceness value of 19
- Adjust the niceness value of the running stress-ng process to 10.

Terminate the stress-ng process.

```bash
#check if the app is installed
dnf list installed | grep stress-ng

#intall if needed
#start stress
nice -n 19 stress-ng -c1 &

#check resource with top
top

#renice the value to 10 with "r" in top view

#extra you can kill process pressing "k" while in top view, you can use sigkill or 9
```
---

## Question 31: 

- Copy /etc/fstab to /var/tmp.
- Set the file owner to root.
- Ensure /var/tmp/fstab is not executable by anyone.
- Configure file ACLs on the copied file to:
- User adam: read & write.
- User maryam: no access.
- All other users: read-only.



Terminate the stress-ng process.

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

## Question 31: On "rhel", create a file rhel-file.ext and securely copy (scp) it to the home dir of user master-server on main-server.

```bash
#on rhel server
touch rhel-file.txt

#copy file to main server
scp -v rhel-file.txt master-server@192.168.15.14:/home/master-server
 ```
---

## Question 32: Create a logical volume named devops_lv with 32 extents
- using the /dev/sdc disk.
- This should be created from a volume group
- named devops_vg with 20MB physical extents.
- Format the logical volume as an ext4 filesystem and mount it
- persistently at /mnt/devops_lv.

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
pvcreate /dev/sdc

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
## Question 33: Create and Mount Swap volume persistently
- From /dev/vdb, create a 800MB swap partition and configure it
to mount persistently.
- All your changes must persist after a reboot.

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
## Question 34: Create and Mount Swap volume persistently
- On rhel-server, recreate the following LVM setup:
- Create a volume group named cloud_vg.
- From this volume group, create a logical volume named cloud_lv.
- The logical volume must have a size of 200 MB.
- Create an appropriate filesystem on the logical volume.
- Mount the filesystem and ensure it is available after reboot.

```bash
#create partition
fdisk /dev/sdc
n
+270M
W

#create volume group
vgcreate cloud_vg /dev/sdc

# create logical volume
lvcreate -L 200M -n cloud_lv cloud_vg

#assign filesystem
mkfs.ext4 /dev/cloud_vg/cloud_lv

#create directory for mounting
mkdir /mnt/cloud_lv

#make it persistant
vim /etc/fstab
/dev/devops_vg/devops_lv                /mnt/devops_lv          ext4    defaults        0 0

#mount it
mount -a 
  
```
---


## Question 35: Resize devops_lv and Configure Swap volume

- On rhel server, resize the existing cloud_lv logical volume to 250MB
(a size between 225–270MB is acceptable), while resizing its filesystem
accordingly.


```bash
  #check logical volumes
  lvs
  #extend
  lvextend -L +50 /dev/cloud_vg/cloud_lv -r

  #lvs to check if it worked
  lvs
```
---

## Question 36: Cron Job Configuration
- Create a cron job for user rhel that runs logger "RHCSA Playlist Now Available" every 2 minutes.

```bash
  #Check if crond is working
  systemctl status crond

  #if not
  systemctl --now enable crond

  #Check current user crontabs
  crontab -l

  #Check specific user crontabs
  crontab -l -u rhel-user

  #create crontab to run as an specific user
  crontab -e -u rhel-user

  #runs logger "RHCSA Playlist Now Available" every 2 minutes.
  */2 * * * * logger "RHCSA Playlist Now Available"
```
---


## Question 37: Use at to write "This task was easy!" to /at-files/at.txt in 2 minutes.

```bash
  #Check if at is installed
  systemctl status atd
  #install and enable if need it

  #create directory
  mkdir /at-files

  #write te message in the file
  echo 'echo "This task was easy!" >> /at-files/at.txt | at now +2 minutes' 

```
---

## Question 38: GRUB Bootloader Modification
- Set GRUB_TIMEOUT=10,
- GRUB_TIMEOUT_STYLE=hidden, and
- add quiet to GRUB_CMDLINE_LINUX.
- Apply your changes to the grub config file.

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
## Question 39: Enable Network Services
- Ensure network services starts at boot.

```bash
  #Enable the service
  systemctl enable --now NetworkManager

  #check
  systemctl status NetworkManager
  
```
---
## Question 40: Firewall Rules
- Allow access SSH and HTTP services using firewall-cmd

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
## Question 41: Create a group named sharegroup and the following users
- haruna (with no login shell, not a member of sharegroup),
- umar (member of sharegroup),
- adoga (with UID 4444 member of sharegroup).
- All users should have a password: persward.
- Change the password of user adoga to perfect.

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
## Question 42: User Password Policies
- Enforce password policy to have a minimum length of 8 chars.
- Set the max password age to 30 days.

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
## Question 43: Delete Users and Groups
- Remove the user umar from sharegroup.
- Delete the sharegroup.
- Delete user haruna with their home directory.

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

## Question 44: Check if firewalld and selinux are active and enable

systemctl status firewalld
systemctl is-active firewalld
systemctl is-enabled firewalld
systemctl enable --now firewalld
sudo vi /etc/selinux/config
SELINUX=enforcing
getenforce
