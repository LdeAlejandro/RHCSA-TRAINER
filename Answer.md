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
ssh-copy-id usuario@servidor
# (Enter password once)

# 3. Test SSH login (should not ask for password)
ssh usuario@servidor
```

```bash
#to check progress:
check with rhcsa-trainer eval
```