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
  deluser "$username" 2> /dev/null || true

  # (re-)create it
  echo "  -> creating $username"
  adduser -D -s /sbin/nologin -g "" -h "$home" -u "$userid" "$username"
  #echo "$username:$password" | chpasswd

  # create a classic passwd-file because dovecot cannot handle the system's shadow file
  echo "$username:$password:$userid:$userid::$home:/sbin/nologin" >> /etc/mail/passwd
done < /etc/mail/accounts

###################################################################
# configure Postfix

echo "Configuring Postfix for host $HOSTNAME ..."

DOMAIN="${DOMAIN:-$HOSTNAME}"

# always include dkimproxy milter
ALL_SMTPD_MILTERS="inet:localhost:8891"
ALL_NON_SMTPD_MILTERS="inet:localhost:8891"

if [ -n "$SMTPD_MILTERS" ]; then
  ALL_SMTPD_MILTERS="$ALL_SMTPD_MILTERS, $SMTPD_MILTERS"
fi

if [ -n "$NON_SMTPD_MILTERS" ]; then
  ALL_NON_SMTPD_MILTERS="$ALL_NON_SMTPD_MILTERS, $NON_SMTPD_MILTERS"
fi

cat /etc/postfix/main.cf.template | sed \
  -e "s|{{TLS_CERTIFICATE}}|$TLS_CERTIFICATE|g" \
  -e "s|{{TLS_PRIVATE_KEY}}|$TLS_PRIVATE_KEY|g" \
  -e "s|{{HOSTNAME}}|$HOSTNAME|g" \
  -e "s|{{DOMAIN}}|$DOMAIN|g" \
  -e "s|{{DESTINATION}}|$DESTINATION|g" \
  -e "s|{{VIRTUAL_DOMAIN_ALIASES}}|$VIRTUAL_DOMAIN_ALIASES|g" \
  -e "s|{{MESSAGE_SIZE_LIMIT}}|$MESSAGE_SIZE_LIMIT|g" \
  -e "s|{{SMTPD_MILTERS}}|$ALL_SMTPD_MILTERS|g" \
  -e "s|{{NON_SMTPD_MILTERS}}|$ALL_NON_SMTPD_MILTERS|g" \
  > /etc/postfix/main.cf

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
