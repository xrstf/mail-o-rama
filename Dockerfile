# Debian because alpine 3.7 has no opensmtpd-extras and no passwd support.
FROM debian:stretch

ENV DEBIAN_FRONTEND=noninteractive

# install dependencies
RUN apt-get update && \
    apt-get install -y \
      ca-certificates \
      dkimproxy \
      dovecot-core \
      dovecot-imapd \
      dovecot-lmtpd \
      opensmtpd \
      supervisor

# setup base directory for all mail data
RUN mkdir -p /var/mail-data && \
    chown dovecot:dovecot /var/mail-data

ADD entrypoint.sh               /
ADD backup.sh                   /
ADD supervisord.conf            /etc/supervisord.conf
ADD smtpd.conf.template         /etc/mail/smtpd.conf.template
ADD dovecot.conf.template       /etc/dovecot/local.conf.template
ADD dkimproxy_out.conf.template /etc/dkimproxy/dkimproxy_out.conf.template

RUN chmod +x /*.sh

VOLUME ["/var/mail-data", "/var/lib/dovecot"]

ENTRYPOINT ["/entrypoint.sh"]
