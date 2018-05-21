# Mail-o-Rama

This is a very simple mail server based on Docker with these features:

* Multiple mail accounts
* Multiple virtual e-mail addresses per account
* SMTP via OpenSMTPD
* IMAP via Dovecot
* DKIM signatures via dkimproxy

Mail-o-Rama is useful for smaller personal e-mail setups. I wrote thise because
the existing alternatives are just not my taste:

* poste.io does not play well when you have an existing Let's Encrypt setup.
* mailcow uses too many containers and has "too many features" for my taste.

There are many other solutions out there, but this one is mine. It does **not**
feature the following:

* **NO** spam filter (though this might change at some point)
* **NO** virus scanner
* **NO** webmailer
* **NO** management UI
* **NO** SQL databases

## Usage

For running the Docker container, you need a couple of text files.

### `accounts`

This file should contain a list of your accounts, one per line. For each account,
you have to spcify a name, a user ID and a password hash. This is very similar
to regular UNIX user information and in fact, this is (also) used to setup system
accounts within the container.

    al    1000 $6$OxCmLiR/Ynm....
    peggy 1001 $6$OxCmLiR/Ynm....
    kelly 1002 $6$OxCmLiR/Ynm....

Make sure to never rename or re-number the accounts without also taking care of
the existing mail data.

### `domains`

This file contains a list of all the domains you want to handle e-mail for, for
example

    bundy.net
    example.com
    chicago.com

You can add or remove domains at any point, this should not affect existing
e-mails.

### `virtuals`

This is the "meat" of your configuration: the list of all existing e-mail
addresses. Each line contains a mapping of e-mail address to one or more user
accounts or external addresses. Separate targets by comma:

    al@bundy.net       al
    al@chicago.com     al
    buck@bundy.net     al
    peggy@bundy.net    peggy
    bud@bundy.net      grandmaster-b@gmail.com
    family@bundy.net   al,peggy,bud@bundy.net

You can manage this file as you like, it should not affect existing mail data.

### `aliases`

This file defines aliases for system accounts. You will probably rarely get
mails from within your container, but this file is used when you relay mails
from the Docker host system into your container (see below).

    root:al
    pumpkin:kelly

### Running the container

See the `docker-compose.yml` file for usage instructions.

## Local System Mail

The goal is to get rid of as much e-mail infrastructure on the host system as
possible. But this leaves the question as to how mails from your cron daemon
reaches your inbox. You have basically two options:

### SMTP-based using an MTA

You can install a classic MTA like sendmail, postfix or exim on your Docker host
and configure it to relay mail to the Docker container via SMTP. This has the
drawback that you need to map your host usernames to e-mail addresses (because
you cannot send an e-mail just to "root"), but at the same time is the only
viable solution when you have other Docker containers that also should send
e-mail.

An easy solution is to use `msmtp`. In many cases (like for Archlinux and Debian)
there's an addtional package, `msmtp-mta`, that provides a `/usr/sbin/sendmail`
program. A sample configuration could look like this:

    # Set default values for all following accounts.
    defaults
    aliases   /etc/aliases.msmtp

    # Mail-o-Rama
    account   mailorama
    host      localhost
    port      25
    from      cron@bundy.net

    # Set a default account
    account default : mailorama

You also want to have an aliases file that maps your user accounts to an e-mail
address. The regular `/etc/aliases` does not work if it contains mappings for
non-existing users, so it's probably a good idea to use a dedicated aliases file
that looks like this:

    root: al@bundy.net
    al: al@bundy.net

It should be very easy to install an MTA like this into your other Docker
containers to have them also properly deliver their mail to you.

### Use `docker exec` and sendmail

Instead of sending e-mail via SMTP to the container, you can also use the
sendmail aliases that's provided by OpenSMTPD. For this, you need something on
your host that runs `docker exec -i <your container> sendmail ...` for each new
mail. In this case, usernames are mappened to mail accounts using the
`/etc/aliases` file *inside the container*.

The `/usr/sbin/sendmail` program cannot be a shellscript, because programs like
cron run it via `popen()`. To work around this, I wrote a very simple Go program
that can be used as your local sendmail program. See the `sendmail/` directory
for the source and some precompiled binaries. Simply place the binary at
`/usr/sbin/sendmail` (or symlink it) and make sure to configure the container
name

* either by setting a system-wide environment variable
  `MAILORAMA_CONTAINER=<full docker container name here>`
* or by creating an INI file in `/etc/mail-o-rama/sendmail.ini` with only one
  setting: `container = <full docker container name here>`

## Backups

As e-mail data is stored in Maildirs, creating a backup can be as simple as
`tar`ing up each mail account. To make things simpler, there is a tiny
`backup.sh` script included in the image which is meant to be called once per
day via

    docker-compose exec mail-o-rama /backup.sh

The script will create tar.gz files (named as ``YYYY-MM-DD.tar.gz``) in each
mail account directory. If you set the `BACKUP_RETENTION_DAYS` environment
variable to a non-empty value, the script will also cleanup old backups
automatically.
