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

* **Option A:** You install an MTA (sendmail, Postfix, eixm) on your host and
  configure it to relay all mail to your port 25. This should work, but I have
  not tested it.
* **Option B:** You use the OpenSMTPD-provided `sendmail` that is already
  installed inside the container. This only requires you to make sure that you
  have a `/usr/sbin/sendmail` program on your Docker host that performs a
  `docker exec -i <container> sendmail ...`.

I chose option B and wrote a very simple Go program that can be used as your
local sendmail program. See the `sendmail/` directory for the source and some
precompiled binaries. Simply place the binary at `/usr/sbin/sendmail` (or
symlink it) and make sure to configure the container name

* either by setting a system-wide environment variable
  `MAILORAMA_CONTAINER=<full docker container name here>`
* or by creating an INI file in `/etc/mail-o-rama/sendmail.ini` with only one
  setting: `container = <full docker container name here>`
