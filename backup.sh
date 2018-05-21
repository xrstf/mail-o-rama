#!/usr/bin/env bash

set -e

base=/var/mail-data
today=$(date +"%Y-%m-%d")

mkdir -p "$base"
cd "$base"

for user in $(doveadm user '*'); do
  backup="$user/backup"

  # create backup mail_location
  mkdir -p "$backup"
  chown -R "$user":"$user" "$backup"

  # perform backup
  doveadm backup -u "$user" "maildir:$base/$backup"

  # and zip everything up
  cd "$base/$user"
  tar czf "$today.tar.gz" backup
  ln -sf "$today.tar.gz" latest-backup.tar.gz

  # optionally remove old backup files
  if [ -n "$BACKUP_RETENTION_DAYS" ]; then
    find -type f -name '*.tar.gz' -mtime +$BACKUP_RETENTION_DAYS -exec rm {} \;
  fi
done
