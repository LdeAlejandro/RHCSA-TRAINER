## Question 1: Use vim to create and save a file hello.txt containing 'hello world'

## Question 2: Create SSH key-based authentication

## Question 3: Check recent system logs

## Question 4: Move the file from the files directory to the Documents directory, then copy it to the DocumentBackup directory — all located inside the user’s home directory.

## Question 5: Find the string "Listen" in /etc/httpd/conf/httpd.conf and save the output to /root/web.txt

## Question 6: Create a gzip-compressed tar archive of /etc named etc_vault.tar.gz in your home directory under vaults (~/vaults).

## Question 7: File Links - Create a file file_a in shorts directory create soft link file_b pointing to file_a

## Question 8: File Links - Create a hard link of the file in hardfiles directory to file_c

## Question 9: Find files in /usr that are greater than 3MB but < 10MB and copy them to /bigfiles directory.

## Question 10: Find files in /etc modified more than 120 days ago and copy them to /var/tmp/twenty/.

## Question 11:Find all files owned by user rhel and copy them to /var/tmp/rhel-files.

## Question 12: Find a file named "httpd.conf" and save the absolute paths to /root/httpd-paths.txt.

## Question 13: Copy the contents of /etc/fstab to /var/tmp, Set the file ownership to root, Ensure no execute permissions for anyone

## Question 14: Give full permissions to everyone on /var/tmp/chmod_lab/public.log and set owner:group to root:root

## Question 15: Allow the owner to read/write/execute, while others can only read and execute on /var/tmp/chmod_lab/script.sh. Set owner:group to devops:devs.

## Question 16: Allow only the owner to read, write, and execute on /var/tmp/chmod_lab/secret.txt. Set owner:group to admin:admins.

## Question 17: Allow the owner to read and write, while others can only read /var/tmp/chmod_lab/document.txt. Set owner:group to student:students.

## Question 18: Allow only the owner to read and write /var/tmp/chmod_lab/private.key. No one else should have access. Set owner:group to tester:qa.

## Question 19: Allow only the owner to read /var/tmp/chmod_lab/readme.md. Everyone else should have no access. Set owner:group to analyst:finance.

## Question 20: Remove all permissions from /var/tmp/chmod_lab/hidden.conf. No one should be able to read, write, or execute it. Set owner:group to backup:storage.

## Question 21: Create a shell script /root/find-files.sh that finds files in /usr between 30KB and 50KB and saves results to /root/sized_files.txt.

## Question 22: Create an user with the name of "noob" password: Aa7338!! and configure so the user has to change the password on the next login.

## Question 23: Create an user with the name "def4ult" with the password: Aa578!!?? and change the password to C546#Ab!

## Question 24: Outputs "Yes, I’m a Systems Engineer." when run with ./career.sh me , Outputs "Okay, they do cloud engineering." when run with ./career.sh they ,Outputs "Usage: ./career.sh me|they" for invalid/empty arguments

## Question 25: Write shell scripts on node1 that create users and groups according to the following parameters:

### Answer:
```bash
maryam:2030:hpc_admin,hpc_managers
adam:2040:sysadmin,
jacob:2050:hpc_admin
```
Write a shell script that sets the passwords of the users maryam, adam and jacob to Password@1.

---