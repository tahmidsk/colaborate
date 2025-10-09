# collaborate
This is a demo repo to collaborate (study purpose)

## Setting Up Ubuntu Server with SSH Key Authentication

This guide explains how to configure a Ubuntu Linux system as a server and access it remotely from another Linux system using SSH key-based authentication for secure remote analysis.

### Prerequisites
- Ubuntu server system (the machine you want to access remotely)
- Client Linux system (the machine you'll connect from)
- Network connectivity between both systems
- Sudo/root access on the Ubuntu server

---

## Part 1: Setting Up the Ubuntu Server

### Step 1: Install OpenSSH Server

On your Ubuntu server, install the OpenSSH server package:

```bash
sudo apt update
sudo apt install openssh-server -y
```

### Step 2: Check SSH Service Status

Verify that the SSH service is running:

```bash
sudo systemctl status ssh
```

If it's not running, start it:

```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

### Step 3: Configure Firewall (if enabled)

Allow SSH through the firewall:

```bash
sudo ufw allow ssh
sudo ufw allow 22/tcp
sudo ufw enable
sudo ufw status
```

### Step 4: Find Your Server's IP Address

Note your server's IP address:

```bash
ip addr show
# or
hostname -I
```

---

## Part 2: Setting Up SSH Key Authentication on Client System

### Step 1: Generate SSH Key Pair on Client

On your client Linux system, generate an SSH key pair:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Or for a more modern and secure key type:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

When prompted:
- **File location**: Press Enter to use default location (`~/.ssh/id_rsa` or `~/.ssh/id_ed25519`)
- **Passphrase**: Enter a strong passphrase (recommended) or press Enter for no passphrase

### Step 2: Copy Public Key to Server

Use `ssh-copy-id` to copy your public key to the server:

```bash
ssh-copy-id username@server_ip_address
```

Example:
```bash
ssh-copy-id john@192.168.1.100
```

If `ssh-copy-id` is not available, manually copy the key:

```bash
cat ~/.ssh/id_rsa.pub | ssh username@server_ip_address "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Step 3: Set Correct Permissions on Server

SSH to the server and ensure correct permissions:

```bash
ssh username@server_ip_address
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
exit
```

---

## Part 3: Configuring SSH Server for Key-Only Authentication (Recommended)

### Step 1: Edit SSH Server Configuration

On the Ubuntu server, edit the SSH configuration file:

```bash
sudo nano /etc/ssh/sshd_config
```

### Step 2: Update Configuration Settings

Find and modify these lines (uncomment if commented):

```
# Disable password authentication (recommended after key setup)
PasswordAuthentication no

# Enable public key authentication
PubkeyAuthentication yes

# Disable root login (security best practice)
PermitRootLogin no

# Disable empty passwords
PermitEmptyPasswords no

# Enable key-based authentication
AuthorizedKeysFile .ssh/authorized_keys
```

### Step 3: Restart SSH Service

Apply the changes:

```bash
sudo systemctl restart ssh
```

**Warning**: Before disabling password authentication, ensure you can successfully log in with your SSH key!

---

## Part 4: Connecting to the Server

### Basic Connection

From your client system:

```bash
ssh username@server_ip_address
```

### Connection with Specific Key

If you have multiple keys:

```bash
ssh -i ~/.ssh/id_rsa username@server_ip_address
```

### Creating SSH Config for Easy Access

Create/edit `~/.ssh/config` on your client:

```bash
nano ~/.ssh/config
```

Add server configuration:

```
Host myserver
    HostName 192.168.1.100
    User username
    Port 22
    IdentityFile ~/.ssh/id_rsa
```

Now you can connect simply with:

```bash
ssh myserver
```

---

## Part 5: Running Remote Analysis

### Execute Single Command

Run a command without logging in:

```bash
ssh username@server_ip_address "command_to_run"
```

Example:

```bash
ssh john@192.168.1.100 "ls -la /home/john/data"
```

### Run Scripts Remotely

Execute a local script on the remote server:

```bash
ssh username@server_ip_address 'bash -s' < local_script.sh
```

### Transfer Files (SCP)

Copy files to server:

```bash
scp local_file.txt username@server_ip_address:/remote/path/
```

Copy files from server:

```bash
scp username@server_ip_address:/remote/path/file.txt ./local_path/
```

Copy directories recursively:

```bash
scp -r local_directory username@server_ip_address:/remote/path/
```

### Transfer Files (RSYNC)

For efficient file synchronization:

```bash
rsync -avz local_directory/ username@server_ip_address:/remote/path/
```

### Run Interactive Analysis

Start an interactive session:

```bash
ssh username@server_ip_address
```

Then run your analysis tools:

```bash
python3 analysis_script.py
R -f analysis.R
jupyter notebook --no-browser --port=8888
```

### Port Forwarding for Remote Applications

Forward remote application to local port (e.g., Jupyter notebook):

```bash
ssh -L 8888:localhost:8888 username@server_ip_address
```

Then access `http://localhost:8888` in your local browser.

### Background Processes with Screen/Tmux

Run long-running analysis that persists after disconnection:

```bash
ssh username@server_ip_address
screen -S analysis_session
# or
tmux new -s analysis_session

# Run your analysis
python3 long_running_analysis.py

# Detach: Ctrl+A then D (screen) or Ctrl+B then D (tmux)
# Reattach later:
screen -r analysis_session
# or
tmux attach -t analysis_session
```

---

## Part 6: Security Best Practices

### 1. Change Default SSH Port

Edit `/etc/ssh/sshd_config`:

```
Port 2222
```

Restart SSH and update firewall:

```bash
sudo systemctl restart ssh
sudo ufw allow 2222/tcp
sudo ufw delete allow 22/tcp
```

### 2. Use Fail2Ban

Install and configure Fail2Ban to prevent brute-force attacks:

```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 3. Keep System Updated

Regularly update your server:

```bash
sudo apt update && sudo apt upgrade -y
```

### 4. Use Strong Passphrases

Always use strong passphrases for SSH keys.

### 5. Limit User Access

Only give SSH access to users who need it:

```bash
# Add to /etc/ssh/sshd_config
AllowUsers username1 username2
```

### 6. Enable Two-Factor Authentication (Optional)

Install and configure Google Authenticator:

```bash
sudo apt install libpam-google-authenticator -y
google-authenticator
```

---

## Part 7: Troubleshooting

### Cannot Connect to Server

1. Check if SSH service is running on server:
   ```bash
   sudo systemctl status ssh
   ```

2. Verify firewall settings:
   ```bash
   sudo ufw status
   ```

3. Check network connectivity:
   ```bash
   ping server_ip_address
   ```

### Permission Denied (publickey)

1. Verify key is in authorized_keys:
   ```bash
   ssh username@server_ip_address
   cat ~/.ssh/authorized_keys
   ```

2. Check permissions:
   ```bash
   ls -la ~/.ssh/
   # .ssh should be 700
   # authorized_keys should be 600
   ```

3. Check SSH server logs:
   ```bash
   sudo tail -f /var/log/auth.log
   ```

### Connection Timeout

1. Verify server IP address
2. Check if server is behind NAT/firewall
3. Ensure port forwarding is configured on router (if needed)

### Key Not Accepted

Try connecting with verbose mode to see details:

```bash
ssh -v username@server_ip_address
```

Or for more verbosity:

```bash
ssh -vvv username@server_ip_address
```

---

## Additional Resources

- [OpenSSH Official Documentation](https://www.openssh.com/)
- [Ubuntu Server Guide - OpenSSH Server](https://ubuntu.com/server/docs/service-openssh)
- [SSH Key Management Best Practices](https://www.ssh.com/academy/ssh/key-management)

---

## Quick Reference Commands

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy key to server
ssh-copy-id username@server_ip

# Connect to server
ssh username@server_ip

# Run remote command
ssh username@server_ip "command"

# Copy file to server
scp file.txt username@server_ip:/path/

# Sync directory to server
rsync -avz local_dir/ username@server_ip:/remote_dir/

# Port forwarding
ssh -L local_port:localhost:remote_port username@server_ip
```
