# 🚀 MongoDB Backup to Email (SendGrid)
A complete, production‑ready, fully automated MongoDB backup system.

This project provides **two powerful Bash scripts** that:

- Create MongoDB backups (with or without authentication)
- Zip the backup
- Email it using SendGrid with a professional HTML template
- Clean all previous backup ZIPs automatically
- Clean SendGrid JSON response files automatically
- Log everything
- Allow full configuration through environment variables
- Support cron automation (daily, weekly, on reboot, etc.)

---

# 📁 Repository Structure

```
/
├── mongo_backup_sendgrid_noauth.sh      # Script for MongoDB without authentication
├── mongo_backup_sendgrid_auth.sh        # Script for MongoDB with username/password
├── README.md                            # Documentation
```

---

# 📦 Features

### ✔ Fully automated backups  
### ✔ Professional HTML email notifications  
### ✔ Supports authenticated & unauthenticated MongoDB  
### ✔ Zero credentials inside code (env‑based config)  
### ✔ Full logging  
### ✔ Cleanup system — keeps only the latest ZIP  
### ✔ Cron‑ready  
### ✔ Works on all Linux systems  

---

# 🎯 Use Cases

- Daily database backup from a server  
- Automatic emergency backup notifications  
- Deploy backups from a VPS, cloud instance, or local machine  
- Store backups in off-site email inbox  
- Cron-based automated retention  

---

# 📘 Requirements

Install MongoDB tools:

```bash
sudo apt install mongodb-database-tools zip curl
```

Check required tools:

```bash
mongodump --version
zip --version
curl --version
```

---

# 🔧 Environment Variables

Create a `.env` (never commit it to GitHub):

```bash
# MongoDB (no auth)
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DB_NAME=mydatabase

# MongoDB (auth version)
MONGO_USER=myuser
MONGO_PASS=mypassword
MONGO_AUTH_DB=admin

# Backup directory
BACKUP_DIR=/home/user/mongodb-backups

# SendGrid
SENDGRID_FROM_EMAIL=backup@example.com
SENDGRID_TO_EMAIL=me@example.com
SENDGRID_API_KEY=SG.xxxxxx

# Optional subject prefix
SENDGRID_SUBJECT_PREFIX=[Backup]
```

Load it:

```bash
export $(grep -v '^#' .env | xargs)
```

---

# ▶️ Running the Scripts

## 1️⃣ No‑Auth Version

```bash
chmod +x mongo_backup_sendgrid_noauth.sh
./mongo_backup_sendgrid_noauth.sh
```

## 2️⃣ Auth Version

```bash
chmod +x mongo_backup_sendgrid_auth.sh
./mongo_backup_sendgrid_auth.sh
```

---

# 📤 HTML Email Example

The email template includes:

- Clean white card UI  
- Header with dark navy bar  
- Backup information table  
- Footer with warning & security notes  

Supports:

- 📁 Attachment (ZIP)
- 📬 Full summary of backup details

---

# 🧹 Cleanup System

Every run:

- Deletes raw MongoDB dump directory  
- Deletes all `sendgrid_response_*.json` files  
- Deletes all previous ZIP backups  
- Keeps **only the latest ZIP backup**  

This ensures:

- Your storage never fills  
- Only your newest backup remains  

---

# 🕛 Cron Automation

## Open cron editor:

```bash
crontab -e
```

Choose **nano** if prompted.

---

## ✔ Run every day at midnight

```cron
0 0 * * * /path/to/mongo_backup_sendgrid_noauth.sh >> /path/to/cron_backup.log 2>&1
```

---

## ✔ Run every 2 minutes (for testing)

```cron
*/2 * * * * /path/to/mongo_backup_sendgrid_noauth.sh >> /path/to/cron_backup.log 2>&1
```

---

## ✔ Run once at reboot

```cron
@reboot /path/to/mongo_backup_sendgrid_noauth.sh >> /path/to/cron_reboot.log 2>&1
```

---

# 🔐 Security Recommendations

- Never commit `.env` files  
- Rotate SendGrid API keys regularly  
- Store `SENDGRID_API_KEY` in `/etc/environment` for production  
- Use firewalls to restrict MongoDB access  
- For production MongoDB:
  - Enable authentication
  - Enable role‑based access
  - Use TLS connections  

---

# 🧪 Troubleshooting Guide

### Email doesn’t arrive?
- Check SendGrid dashboard → **Email Activity**
- Ensure `SENDGRID_FROM_EMAIL` is verified
- Check spam/promotions tabs

### Dump directory not created?
- Verify `mongodump` installed
- Check DB name
- Ensure MongoDB is running

### Cron doesn’t execute script?
- Ensure script is executable:
  ```bash
  chmod +x script.sh
  ```
- Use absolute paths
- Check system log:
  ```bash
  grep CRON /var/log/syslog
  ```

---

# 📄 Recommended `.gitignore`

```
.env
*.zip
sendgrid_response_*.json
mongo_backup.log
cron_backup.log
cron_reboot.log
```

---

# ❤️ Contributions

Pull requests are welcome.  
Feel free to improve:

- Email design  
- Security
- Backup strategy
- Multi‑database support
- Cloud storage integration (S3/Google Drive/Dropbox)

---

# 📜 License

GNU License — free for commercial & personal use.

---

# 🌟 Support / Contact

If you need help improving the script or customizing it for production, feel free to open an issue.
