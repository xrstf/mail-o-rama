#!/usr/bin/env sh

set -e

# TODO: check existence of env variables

###################################################################
# create system users for each user

echo "Creating e-mail accounts ..."
echo > /etc/mail/passwd

while read line; do
  username=$(echo "$line" | cut -d" " -f1)
  userid=$(echo "$line" | cut -d" " -f2)
  password=$(echo "$line" | cut -d" " -f3)
  home="/var/mail-data/$username"

  # first delete a possibly existing user account
  deluser --quiet "$username" 2> /dev/null || true

  # (re-)create it
  echo "  -> creating $username"
  adduser --quiet --disabled-login --disabled-password --gecos "" --home "$home" --uid "$userid" "$username"
  #echo "$username:$password" | chpasswd

  # create a classic passwd-file because dovecot cannot handle the system's shadow file
  echo "$username:$password:$userid:$userid::$home:/bin/nologin" >> /etc/mail/passwd
done < /etc/mail/accounts

###################################################################
# configure opensmtpd

echo "Configuring OpenSMTPD for host $HOSTNAME ..."

cat /etc/mail/smtpd.conf.template | sed \
  -e "s|{{TLS_CERTIFICATE}}|$TLS_CERTIFICATE|g" \
  -e "s|{{TLS_PRIVATE_KEY}}|$TLS_PRIVATE_KEY|g" \
  -e "s|{{HOSTNAME}}|$HOSTNAME|g" \
  > /etc/mail/smtpd.conf

###################################################################
# configure dovecot

echo "Configuring Dovecot ..."

cat /etc/dovecot/local.conf.template | sed \
  -e "s|{{TLS_CERTIFICATE}}|$TLS_CERTIFICATE|g" \
  -e "s|{{TLS_PRIVATE_KEY}}|$TLS_PRIVATE_KEY|g" \
  > /etc/dovecot/local.conf

chown dovecot:dovecot /var/mail-data

# remove any pre-existing passdb and userdb configurations
echo > /etc/dovecot/conf.d/auth-system.conf.ext

###################################################################
# configure dkimproxy

echo "Configuring DKIMproxy ..."

cat /etc/dkimproxy/dkimproxy_out.conf.template | sed \
  -e "s|{{HOSTNAME}}|$HOSTNAME|g" \
  -e "s|{{PRIVATE_KEY}}|$DKIM_PRIVATE_KEY|g" \
  -e "s|{{SELECTOR}}|$DKIM_SELECTOR|g" \
  -e "s|{{MIN_SERVERS}}|${DKIM_MIN_SERVERS:-1}|g" \
  > /etc/dkimproxy/dkimproxy_out.conf

###################################################################
# fire up services

echo "Handing control over to supervisord. Good luck!"

exec /usr/bin/supervisord -c /etc/supervisord.conf
