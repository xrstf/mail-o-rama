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
addresses. Each line contains a mapping of e-mail address to user account:

    al@bundy.net    al
    al@chicago.com  al
    buck@bundy.net  al
    peggy@bundy.net peggy

You can manage this file as you like, it should not affect existing mail data.

### `aliases`

This file defines aliases for system accounts. Since you probably will not have
mails originating from inside your container, this file is not really used.

    root:al
    pumpkin:kelly

### Running the container

See the `docker-compose.yml` file for usage instructions.

