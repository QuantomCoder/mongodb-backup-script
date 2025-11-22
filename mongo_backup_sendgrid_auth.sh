#!/usr/bin/env bash
#
# mongo_backup_sendgrid_auth.sh
#
# Description:
#   Backup a MongoDB database (with username/password auth), zip it,
#   and email it via SendGrid. All configuration comes from env vars.
#
# Required environment variables:
#   MONGO_DB_NAME          - MongoDB database name
#   MONGO_USER             - MongoDB username
#   MONGO_PASS             - MongoDB password
#   MONGO_AUTH_DB          - Authentication database (e.g. "admin")
#   BACKUP_DIR             - Directory where backups & logs are stored
#   SENDGRID_FROM_EMAIL    - "From" email address (must be verified in SendGrid)
#   SENDGRID_TO_EMAIL      - Destination email address
#   SENDGRID_API_KEY       - SendGrid API key
#
# Optional environment variables:
#   MONGO_HOST             - MongoDB host (default: localhost)
#   MONGO_PORT             - MongoDB port (default: 27017)
#   SENDGRID_SUBJECT_PREFIX - Prefix for email subject line (e.g. "[Production]")
#

set -euo pipefail

#####################################
# Configuration from environment
#####################################

MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT="${MONGO_PORT:-27017}"

: "${MONGO_DB_NAME:?MONGO_DB_NAME is required}"
: "${MONGO_USER:?MONGO_USER is required}"
: "${MONGO_PASS:?MONGO_PASS is required}"
: "${MONGO_AUTH_DB:?MONGO_AUTH_DB is required}"
: "${BACKUP_DIR:?BACKUP_DIR is required}"
: "${SENDGRID_FROM_EMAIL:?SENDGRID_FROM_EMAIL is required}"
: "${SENDGRID_TO_EMAIL:?SENDGRID_TO_EMAIL is required}"
: "${SENDGRID_API_KEY:?SENDGRID_API_KEY is required}"

SENDGRID_SUBJECT_PREFIX="${SENDGRID_SUBJECT_PREFIX:-MongoDB Backup}"

LOG_FILE="${BACKUP_DIR}/mongo_backup_auth.log"

#####################################
# Logging helpers
#####################################

log() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts="$(date +'%Y-%m-%d %H:%M:%S')"
  echo "[$ts] [$level] $msg" | tee -a "$LOG_FILE"
}

trap 'log ERROR "Script failed at line $LINENO"' ERR

#####################################
# Pre-flight checks
#####################################

mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

for cmd in mongodump zip curl base64; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log ERROR "'$cmd' is not installed or not in PATH."
    exit 1
  fi
done

log INFO "Starting MongoDB backup (auth) for database '$MONGO_DB_NAME'"

#####################################
# Create dump & ZIP
#####################################

DATE="$(date +'%Y-%m-%d_%H-%M-%S')"
DUMP_DIR="${BACKUP_DIR}/${MONGO_DB_NAME}_dump_${DATE}"
ARCHIVE_PATH="${BACKUP_DIR}/${MONGO_DB_NAME}_backup_${DATE}.zip"

log INFO "Dumping MongoDB database '$MONGO_DB_NAME' into '$DUMP_DIR'..."
log INFO "Running: mongodump --host $MONGO_HOST --port $MONGO_PORT --db $MONGO_DB_NAME --username *** --authenticationDatabase $MONGO_AUTH_DB --out $DUMP_DIR"

if ! mongodump \
  --host "$MONGO_HOST" \
  --port "$MONGO_PORT" \
  --db "$MONGO_DB_NAME" \
  --username "$MONGO_USER" \
  --password "$MONGO_PASS" \
  --authenticationDatabase "$MONGO_AUTH_DB" \
  --out "$DUMP_DIR" >>"$LOG_FILE" 2>&1; then
  log ERROR "mongodump failed, see $LOG_FILE for details."
  exit 1
fi

if [[ ! -d "$DUMP_DIR" ]]; then
  log ERROR "Dump directory '$DUMP_DIR' does not exist after mongodump. Aborting."
  log INFO "Contents of backup dir '$BACKUP_DIR':"
  ls -l "$BACKUP_DIR" | tee -a "$LOG_FILE"
  exit 1
fi

log INFO "Dump directory exists. Creating ZIP archive '$ARCHIVE_PATH'..."

if ! zip -r "$ARCHIVE_PATH" "$DUMP_DIR" >>"$LOG_FILE" 2>&1; then
  log ERROR "Failed to create ZIP archive. See $LOG_FILE for details."
  exit 1
fi

#####################################
# Encode archive for SendGrid
#####################################

log INFO "Encoding archive to base64 for email attachment..."
BASE64_CONTENT="$(base64 "$ARCHIVE_PATH" | tr -d '\n')"

#####################################
# Send email via SendGrid
#####################################

log INFO "Sending email via SendGrid to $SENDGRID_TO_EMAIL..."

SENDGRID_RESPONSE_FILE="${BACKUP_DIR}/sendgrid_response_${DATE}.json"
SUBJECT="${SENDGRID_SUBJECT_PREFIX}: ${MONGO_DB_NAME} at ${DATE}"

HTTP_STATUS=$(
  curl \
    --show-error \
    --request POST \
    --url https://api.sendgrid.com/v3/mail/send \
    --header "Authorization: Bearer $SENDGRID_API_KEY" \
    --header 'Content-Type: application/json' \
    --data @- \
    --write-out "%{http_code}" \
    --output "$SENDGRID_RESPONSE_FILE" <<EOF
{
  "personalizations": [{
    "to": [{ "email": "$SENDGRID_TO_EMAIL" }]
  }],
  "from": { "email": "$SENDGRID_FROM_EMAIL" },
  "subject": "$SUBJECT",
  "content": [{
    "type": "text/html",
    "value": "<!DOCTYPE html><html><body style='margin:0; padding:0; background:#f4f5f7; font-family:Arial, sans-serif;'><div style='max-width:600px; margin:40px auto; background:#ffffff; border-radius:12px; box-shadow:0 4px 16px rgba(15,23,42,0.12); overflow:hidden;'><div style='padding:20px 24px; background:#0f172a; color:#ffffff;'><h1 style='margin:0; font-size:18px;'>MongoDB Backup Completed</h1><p style='margin:4px 0 0 0; font-size:13px; opacity:0.85;'>Authenticated backup notification</p></div><div style='padding:24px 28px;'><p style='font-size:14px; color:#111827; margin-top:0;'>A new backup has been created for the database <strong>$MONGO_DB_NAME</strong>.</p><table style='width:100%; border-collapse:collapse; margin:16px 0; font-size:13px;'><tr><td style='padding:6px 0; color:#6b7280; width:120px;'>Database</td><td style='padding:6px 0; color:#111827;'><strong>$MONGO_DB_NAME</strong></td></tr><tr><td style='padding:6px 0; color:#6b7280;'>Created at</td><td style='padding:6px 0; color:#111827;'><strong>$DATE</strong></td></tr><tr><td style='padding:6px 0; color:#6b7280;'>Host</td><td style='padding:6px 0; color:#111827;'>$MONGO_HOST:$MONGO_PORT</td></tr><tr><td style='padding:6px 0; color:#6b7280;'>Auth DB</td><td style='padding:6px 0; color:#111827;'>$MONGO_AUTH_DB</td></tr></table><p style='font-size:13px; color:#4b5563; line-height:1.6;'>The backup is attached as a ZIP file. Store it securely and rotate credentials periodically.</p><div style='margin-top:20px; padding:12px 16px; border-radius:8px; background:#eff6ff; border:1px solid #dbeafe; font-size:12px; color:#1e3a8a;'><strong>Security Note:</strong> This backup may contain sensitive data. Ensure access is restricted and consider encrypting the file at rest.</div></div><div style='padding:14px 24px; background:#f9fafb; font-size:11px; color:#9ca3af; text-align:center;'>This email was generated automatically by the MongoDB backup script.<br/>If you did not expect this message, please rotate your MongoDB and SendGrid credentials.</div></div></body></html>"
  }],
  "attachments": [{
    "content": "$BASE64_CONTENT",
    "type": "application/zip",
    "filename": "$(basename "$ARCHIVE_PATH")"
  }]
}
EOF
)

log INFO "SendGrid HTTP status: $HTTP_STATUS"
log INFO "SendGrid raw response saved to: $SENDGRID_RESPONSE_FILE"

if [[ "$HTTP_STATUS" -lt 200 || "$HTTP_STATUS" -ge 300 ]]; then
  log ERROR "SendGrid API returned non-2xx status. See $SENDGRID_RESPONSE_FILE for details."
  exit 1
fi

log INFO "Email sent successfully."

#####################################
# Cleanup
#####################################

log INFO "Cleaning up raw dump directory '$DUMP_DIR'..."
rm -rf "$DUMP_DIR"

log INFO "Deleting old ZIP backups (keeping only $(basename "$ARCHIVE_PATH"))..."
find "$BACKUP_DIR" -maxdepth 1 -name "*.zip" ! -name "$(basename "$ARCHIVE_PATH")" -type f -delete

log INFO "Deleting all SendGrid response JSON files..."
rm -f "$BACKUP_DIR"/sendgrid_response_*.json

log INFO "Cleanup done. Latest backup kept at: $ARCHIVE_PATH"
