## Question 1
On the local system, create a file named hello.txt in the current working directory. The file must contain the text "hello world". Save the file and ensure the content is written successfully.

## Question 2
Configure SSH key-based authentication between the local system and a remote host. Ensure the user can log in to the remote system without being prompted for a password.

## Question 3
As an administrator, review recent system activity. Examine system logs, including authentication-related events, and verify the status of the SSH service using available log sources.

## Question 4
A file named "move me to document and copy me to backup" exists in /trainer/files. Move the file to /trainer/Documents and then create a copy of it in /trainer/DocumentBackup.

## Question 5
On the system, identify all entries containing the string "Listen" in the Apache HTTP Server configuration file. Save the results to /root/web.txt.

## Question 6
Create a directory named ~/vaults. Archive the entire /etc directory into a gzip-compressed tar file named etc_vault.tar.gz and store it in ~/vaults.

## Question 7
Create a directory named /shorts. Inside this directory create a file named file_a. Create a symbolic link named /file_b that points to /shorts/file_a.

## Question 8
A file named /hardfiles/file_data already exists on the system. Create a hard link named /file_c that references this file.

## Question 9
Create the directory /bigfiles. Locate all regular files under /usr that are larger than 3 MB and smaller than 10 MB, then copy them to /bigfiles.

## Question 10
Create the directory /var/tmp/twenty. Locate all regular files under /etc that were modified more than 120 days ago and copy them to /var/tmp/twenty.

## Question 11
Create the directory /var/tmp/rhel-files. Locate all regular files under /tmp owned by the user rhel and copy them to /var/tmp/rhel-files.

## Question 12
Locate all files named httpd.conf on the system and save their absolute paths to /root/httpd-paths.txt.

## Question 13
Copy /etc/fstab to /var/tmp. Configure the copied file so that it is owned by root:root and cannot be executed by any user.

## Question 14
Configure /var/tmp/chmod_lab/public.log so that it is owned by root:root and all users have full access to the file.

## Question 15
Configure /var/tmp/chmod_lab/script.sh with the following requirements:
- Owner: devops
- Group: devs
- Owner must have read, write, and execute permissions
- Group members must have read and execute permissions
- Other users must have read and execute permissions

Ensure the required user and group exist on the system.

## Question 16
Configure /var/tmp/chmod_lab/secret.txt with the following requirements:
- Owner: admin
- Group: admins
- Only the owner must have access to the file.
- The owner must be able to read, write, and execute the file.

## Question 17
Configure /var/tmp/chmod_lab/document.txt with the following requirements:
- Owner: student
- Group: students
- The owner must have read and write permissions.
- All other users must have read-only access.

## Question 18
Configure /var/tmp/chmod_lab/private.key with the following requirements:
- Owner: tester
- Group: qa
- The owner must have read and write permissions.
- No other user should have access to the file.

## Question 19
Configure /var/tmp/chmod_lab/readme.md with the following requirements:
- Owner: analyst
- Group: finance
- The owner must have read-only access.
- No other user should have access to the file.

## Question 20
Configure /var/tmp/chmod_lab/hidden.conf with the following requirements:
- Owner: backup
- Group: storage
- No user should have any permissions on the file.

## Question 21
Create a shell script named /root/find-files.sh that locates all regular files under /usr with a size between 30 KB and 50 KB. The script must save the results to /root/sized_files.txt.

## Question 22
Create a local user account named noob with the password Aa7338!!. Configure the account so that the user is required to change the password at the next login.

## Question 23
Create a local user account named def4ult and assign the password Aa578!!??. After the account is created, change the password to C546#Ab!.

## Question 24
Create a shell script named career.sh in the root user's home directory with the following behavior:
- When executed with the argument me, it must display: "Yes, I'm a Systems Engineer."
- When executed with the argument they, it must display: "Okay, they do cloud engineering."
- For invalid or missing arguments, it must display: "Usage: ./career.sh me|they"
- The script must have permissions set to 755.

## Question 25
On node1, create shell scripts that automate user and group administration according to the requirements below.

Requirements:
- Create groups using the specified group names and GIDs.
- Create users using the specified usernames, UIDs, and supplementary group memberships.
- Configure the password Strong!2025 for users maryam, adam, and jacob.

## Question 26
Reset the root password on the local system by using GRUB recovery mode. Set the root password to hoppy and ensure the system can boot normally after the password reset.

## Question 27
On rhel-server, review the system tuning configuration and apply the recommended tuning profile. Configure SELinux to operate in permissive mode and ensure the appropriate network service is enabled and configured to start automatically at boot.

## Question 28
Configure SELinux so that the system operates in permissive mode after a reboot. Verify that the configuration persists across system restarts.

## Question 29
Ensure that the system networking service is enabled and configured to start automatically during system boot.

## Question 30
Configure persistent systemd journal logging so that log data is retained across reboots.

## Question 31
A workload testing utility is installed on the system. Perform the following tasks:
- Start a stress-ng process with a niceness value of 19.
- Modify the running process so that its niceness value becomes 10.
- Terminate the process when finished.

## Question 32
Copy the file /etc/fstab to /var/tmp and configure access according to the following requirements:
- The file owner must be root.
- The file must not be executable by any user.
- User adam must have read and write access.
- User maryam must have no access.
- All other users must have read-only access.

## Question 33
On rhel, create a file named rhel-file.txt in the current user's environment and securely transfer it to the home directory of user master-server on main-server.

## Question 34
Create a logical volume named devops_lv using storage provided by /dev/sdc. The logical volume must be created from a volume group named devops_vg with physical extents of 20 MB. Configure the logical volume with 32 extents, create an ext4 filesystem on it, and mount it persistently at /mnt/devops_lv.

## Question 35
Using the disk /dev/sdd, create an 800 MB swap partition and configure the system so that the swap space is activated automatically after reboot. Verify that the swap space is available."

## Question 36
On rhel-server, configure local storage according to the following requirements:
- Create a volume group named cloud_vg.
- Create a logical volume named cloud_lv from cloud_vg.
- The logical volume must have a size of 200 MB.
- Create an appropriate filesystem on the logical volume.
- Mount the filesystem and ensure it is available after a system reboot.

## Question 37
An existing logical volume named cloud_lv requires additional storage.

Resize cloud_lv so that its final size is 250 MB. A final size between 225 MB and 270 MB is acceptable. Ensure the filesystem is resized accordingly.

## Question 38
Configure a scheduled task for user rhel-user that records the message "RHCSA Playlist Now Available" in the system logs every 2 minutes.

## Question 39
Schedule a one-time job that writes the text "This task was easy!" to /at-files/at.txt exactly 2 minutes from now.

## Question 40
Modify the GRUB bootloader configuration with the following requirements:
- Set GRUB_TIMEOUT to 10.
- Set GRUB_TIMEOUT_STYLE to hidden.
- Add the quiet kernel parameter to GRUB_CMDLINE_LINUX.
- Regenerate the GRUB configuration so the changes take effect.

## Question 41
Ensure that the system network management service is enabled and automatically starts at boot.

## Question 42
Configure the firewall to allow access to the following services permanently:
- SSH
- HTTP

Apply the configuration so that the changes take effect immediately.

## Question 43
Create a group named sharegroup and configure the following user accounts:
- haruna must not be able to log in interactively and must not be a member of sharegroup.
- umar must be a member of sharegroup.
- adoga must have UID 4444 and be a member of sharegroup.

Configure the password persward for all users. Afterward, change the password of user adoga to perfect.

## Question 44
Configure the system password policy to meet the following requirements:
- Passwords must have a minimum length of 8 characters.
- User passwords must expire after 30 days.

## Question 45
Perform the following administrative tasks:
- Remove user umar from the sharegroup group.
- Delete the sharegroup group.
- Remove the user haruna and delete the user's home directory.

## Question 46
Verify that firewalld and SELinux are enabled and active on the system. If firewalld is not running, configure it to start immediately and automatically at boot. Ensure SELinux is configured in enforcing mode.
---

```md
## Question 47
Configure a connection named static-enp0s8 on interface enp0s8 with the following settings:

- IPv4 Address: 192.168.100.50/24
- Gateway: 192.168.100.1
- DNS Server: 8.8.8.8

Ensure the configuration persists after a system reboot.

---

## Question 48
Configure interface enp0s8 with the following IPv6 settings:

- IPv6 Address: 2001:db8::10/64
- Gateway: 2001:db8::1

Activate the configuration immediately.

---

## Question 49
Configure the system hostname as:

rhcsa-server.example.com

Ensure the hostname persists after a reboot.

---

## Question 50
Configure the active network connection to use the following DNS servers:

- 1.1.1.1
- 8.8.8.8

Verify that hostname resolution functions correctly.

---

## Question 51
The network connection enp0s8 exists but is currently disconnected.

Restore network connectivity and ensure the connection activates automatically at system boot.

---

## Question 52
A process named stress-ng is consuming excessive CPU resources.

Locate the process and terminate it.

---

## Question 53
Start a process with a niceness value of 15.

Modify the running process so that its niceness value becomes 5.

---

## Question 54
Identify the five processes currently consuming the most memory on the system.

---

## Question 55
Locate all messages generated by the sshd service during the current boot session.

---

## Question 56
Locate all system log messages generated during the last 30 minutes.

---

## Question 57
Configure the system so that journal logs are retained across system reboots.

---

## Question 58
Configure the system to synchronize time with pool.ntp.org.

Verify that time synchronization is functioning correctly.

---

## Question 59
Configure the system to use the following host as its NTP source:

server1.example.com

Verify that the configuration is active.

---

## Question 60
Configure SELinux so that the Apache web server is permitted to access user home directories.

Ensure the configuration persists across reboots.

---

## Question 61
Create the directory:

/webdata

Configure SELinux so that the Apache web server can permanently serve content from this directory.

---

## Question 62
Configure the Apache web server to listen on TCP port 8080.

Adjust SELinux settings as required to permit access to this port.

---

## Question 63
Create a custom systemd service named backup.service.

The service must execute the script:

/root/backup.sh

Ensure the service definition is correctly recognized by systemd.

---

## Question 64
Configure backup.service so that it starts automatically during system boot.

Verify that the service is enabled.

---

## Question 65
An existing XFS filesystem requires additional storage.

Extend the filesystem without unmounting it and verify that the additional capacity is available.

---

## Question 66
Configure the firewall to permanently allow access to TCP port 8080.

Apply the configuration immediately.

---

## Question 67
Configure the firewall to permanently allow access to the NFS service.

Verify that the service is permitted through the firewall.

---

## Question 68
Configure a firewall rich rule that permits SSH access only from the following network:

192.168.100.0/24

Apply the configuration immediately.

---

## Question 69
Create a shell script that receives a username as an argument.

The script must behave as follows:

- If the user exists, display:
  User Exists
- If the user does not exist, display:
  User Not Found

The script must be executable.

---

## Question 70
Create a shell script that accepts multiple filenames as command-line arguments.

The script must display only the filenames that currently exist on the system.

The script must be executable.
```
