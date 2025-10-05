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
