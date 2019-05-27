# Debian because alpine 3.7 has no opensmtpd-extras and no passwd support.
FROM alpine:3.9

# install dependencies
RUN apk add -U --no-cache \
      ca-certificates \
      dkimproxy \
      dovecot \
      dovecot-lmtpd \
      dovecot-pigeonhole-plugin \
      postfix \
      supervisor

# setup base directory for all mail data
RUN mkdir -p /var/mail-data && \
    chown dovecot:dovecot /var/mail-data

ADD entrypoint.sh               /
ADD backup.sh                   /
ADD supervisord.conf            /etc/supervisord.conf
ADD main.cf.template            /etc/postfix/main.cf.template
ADD dovecot.conf.template       /etc/dovecot/local.conf.template
ADD dkimproxy_out.conf.template /etc/dkimproxy/dkimproxy_out.conf.template

RUN chmod +x /*.sh

VOLUME ["/var/mail-data", "/var/lib/dovecot", "/var/spool/postfix"]

ENTRYPOINT ["/entrypoint.sh"]
